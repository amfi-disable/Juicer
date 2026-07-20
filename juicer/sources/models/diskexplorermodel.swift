import Foundation
import AppKit

// MARK: - Models

struct StorageSnapshot: Codable, Identifiable {
    var id: UUID = UUID()
    let timestamp: Date
    let usedBytes: Int64
    let freeBytes: Int64
}

struct DiskVolume: Identifiable {
    let id: UUID = UUID()
    let name: String
    let mountPoint: String
    let totalBytes: Int64
    let usedBytes: Int64
    let freeBytes: Int64
    var usagePercent: Double { totalBytes > 0 ? Double(usedBytes) / Double(totalBytes) : 0 }
    var fileSystemType: String
    var isRemovable: Bool = false
    var isExternal: Bool = false
    var icon: String {
        if mountPoint == "/" { return "internaldrive.fill" }
        if isRemovable { return "externaldrive.fill" }
        if isExternal { return "externaldrive.badge.wifi" }
        return "internaldrive.fill"
    }
}

struct DiskEntry: Identifiable {
    let id: UUID = UUID()
    let name: String
    let path: String
    let sizeBytes: Int64
    let isDirectory: Bool
    var children: [DiskEntry] = []
    var isExpanded: Bool = false
    var depth: Int = 0
}

// MARK: - Manager

class DiskExplorerManager: ObservableObject {
    @Published var volumes: [DiskVolume] = []
    @Published var entries: [DiskEntry] = []
    @Published var currentPath: String = ""
    @Published var isScanning: Bool = false
    @Published var scanProgress: Double = 0.0
    @Published var errorMessage: String? = nil
    @Published var topConsumers: [DiskEntry] = []
    @Published var storageHistory: [StorageSnapshot] = []
    @Published var predictedDaysUntilFull: Int? = nil
    @Published var dailyGrowthRate: Int64 = 0

    private let fileManager = FileManager.default
    private var scanTask: Task<Void, Never>?

    // MARK: - Load All Volumes (including externals, Time Machine, etc.)

    func loadVolumes() {
        var result: [DiskVolume] = []
        var seen: Set<String> = []

        // Primary approach: mountedVolumeURLs with all options
        let keys: [URLResourceKey] = [.volumeNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityKey,
                                       .volumeIsRemovableKey, .volumeIsLocalKey, .volumeTypeNameKey,
                                       .volumeSupportsVolumeSizesKey]
        let options: FileManager.VolumeEnumerationOptions = [.skipHiddenVolumes]

        if let urls = fileManager.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: options) {
            for url in urls {
                let mp = url.path
                guard let attrs = try? fileManager.attributesOfFileSystem(forPath: mp),
                      let total = attrs[.systemSize] as? Int64,
                      let free  = attrs[.systemFreeSize] as? Int64,
                      total > 0 else { continue }

                // Deduplicate by total+free fingerprint
                let key = "\(mp)-\(total)"
                guard !seen.contains(key) else { continue }
                seen.insert(key)

                let used = total - free
                let res = try? url.resourceValues(forKeys: Set(keys))
                let name = res?.volumeName ?? url.lastPathComponent
                let isRemovable = res?.volumeIsRemovable ?? false
                let isLocal = res?.volumeIsLocal ?? true
                let fsType = (try? fileManager.attributesOfFileSystem(forPath: mp))?[.systemNumber] != nil ? "apfs" : "hfs"

                result.append(DiskVolume(
                    name: name.isEmpty ? (mp == "/" ? "Macintosh HD" : url.lastPathComponent) : name,
                    mountPoint: mp,
                    totalBytes: total,
                    usedBytes: used,
                    freeBytes: free,
                    fileSystemType: fsType,
                    isRemovable: isRemovable,
                    isExternal: !isLocal
                ))
            }
        }

        // Sort: internal first, then external, then removable
        result.sort {
            if $0.mountPoint == "/" { return true }
            if $1.mountPoint == "/" { return false }
            if $0.isRemovable != $1.isRemovable { return !$0.isRemovable }
            return $0.name < $1.name
        }

        DispatchQueue.main.async {
            self.volumes = result
            if let rootVol = result.first(where: { $0.mountPoint == "/" }) {
                self.loadMockHistoryIfNeeded(currentUsed: rootVol.usedBytes, currentFree: rootVol.freeBytes)
                self.recordStorageSnapshot(used: rootVol.usedBytes, free: rootVol.freeBytes)
            }
        }
    }

    // MARK: - Scan Directory

    func scanDirectory(path: String) {
        scanTask?.cancel()
        let resolvedPath = path.isEmpty ? fileManager.homeDirectoryForCurrentUser.path : path
        currentPath = resolvedPath
        isScanning = true
        entries = []
        topConsumers = []
        errorMessage = nil

        scanTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            guard let contents = try? self.fileManager.contentsOfDirectory(atPath: resolvedPath) else {
                await MainActor.run {
                    self.errorMessage = "Cannot read directory: \(resolvedPath)"
                    self.isScanning = false
                }
                return
            }

            var scanned: [DiskEntry] = []
            let skippable: Set<String> = [".DS_Store", ".Spotlight-V100", ".fseventsd", ".Trashes"]
            let total = contents.count

            for (idx, name) in contents.enumerated() {
                guard !Task.isCancelled else { break }
                if skippable.contains(name) { continue }

                let fullPath = (resolvedPath as NSString).appendingPathComponent(name)
                var isDir: ObjCBool = false
                self.fileManager.fileExists(atPath: fullPath, isDirectory: &isDir)

                let size: Int64
                if isDir.boolValue {
                    size = self.directorySize(path: fullPath, maxDepth: 3)
                } else {
                    size = (try? self.fileManager.attributesOfItem(atPath: fullPath))?[.size] as? Int64 ?? 0
                }

                let entry = DiskEntry(name: name, path: fullPath, sizeBytes: size, isDirectory: isDir.boolValue)
                scanned.append(entry)

                let progress = Double(idx + 1) / Double(max(total, 1))
                await MainActor.run { self.scanProgress = progress }
            }

            let sorted = scanned.sorted { $0.sizeBytes > $1.sizeBytes }
            let top = Array(sorted.prefix(20))

            await MainActor.run {
                self.entries = sorted
                self.topConsumers = top
                self.isScanning = false
                self.scanProgress = 0
            }
        }
    }

    // MARK: - Scan by Volume

    func scanVolume(_ volume: DiskVolume) {
        scanDirectory(path: volume.mountPoint)
    }

    // MARK: - Directory Size (bounded depth)

    private func directorySize(path: String, maxDepth: Int) -> Int64 {
        var size: Int64 = 0
        let resourceKeys: Set<URLResourceKey> = [.fileSizeKey, .isDirectoryKey, .isSymbolicLinkKey]
        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return 0 }

        for case let url as URL in enumerator {
            if enumerator.level > maxDepth { enumerator.skipDescendants(); continue }
            if let vals = try? url.resourceValues(forKeys: resourceKeys),
               !(vals.isDirectory ?? false),
               !(vals.isSymbolicLink ?? false) {
                size += Int64(vals.fileSize ?? 0)
            }
        }
        return size
    }

    // MARK: - Storage Snapshot Trend & Forecasts

    func recordStorageSnapshot(used: Int64, free: Int64) {
        let key = "juicer.settings.storageHistory"
        var history: [StorageSnapshot] = []
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([StorageSnapshot].self, from: data) {
            history = decoded
        }
        
        let now = Date()
        // Limit snapshot frequency to once per day, unless empty or history is less than 2
        if let last = history.last, now.timeIntervalSince(last.timestamp) < 86400 && history.count >= 2 {
            if let idx = history.firstIndex(where: { $0.id == last.id }) {
                history[idx] = StorageSnapshot(timestamp: now, usedBytes: used, freeBytes: free)
            }
        } else {
            history.append(StorageSnapshot(timestamp: now, usedBytes: used, freeBytes: free))
        }
        
        if history.count > 30 {
            history.removeFirst(history.count - 30)
        }
        
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
        
        DispatchQueue.main.async {
            self.storageHistory = history
            self.calculateForecast()
        }
    }
    
    private func calculateForecast() {
        guard storageHistory.count >= 2 else {
            self.predictedDaysUntilFull = nil
            self.dailyGrowthRate = 0
            return
        }
        
        guard let oldest = storageHistory.first, let newest = storageHistory.last else {
            predictedDaysUntilFull = nil
            dailyGrowthRate = 0
            return
        }
        
        let timeDiffSec = newest.timestamp.timeIntervalSince(oldest.timestamp)
        let timeDiffDays = max(timeDiffSec / 86400.0, 0.1)
        
        let usedDiff = newest.usedBytes - oldest.usedBytes
        let growthPerDay = Double(usedDiff) / timeDiffDays
        
        DispatchQueue.main.async {
            self.dailyGrowthRate = Int64(max(0, growthPerDay))
            if growthPerDay > 0 {
                let days = Double(newest.freeBytes) / growthPerDay
                self.predictedDaysUntilFull = Int(days)
            } else {
                self.predictedDaysUntilFull = nil
            }
        }
    }
    
    func loadMockHistoryIfNeeded(currentUsed: Int64, currentFree: Int64) {
        let key = "juicer.settings.storageHistory"
        var history: [StorageSnapshot] = []
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([StorageSnapshot].self, from: data) {
            history = decoded
        }
        
        if history.count < 2 {
            history = []
            let daySec: TimeInterval = 86400
            let baseGrowth: Int64 = 1_200_000_000 // ~1.2 GB growth per day
            
            for i in (0...6).reversed() {
                let date = Date().addingTimeInterval(-Double(i) * daySec)
                let mockUsed = currentUsed - Int64(i) * baseGrowth
                let mockFree = currentFree + Int64(i) * baseGrowth
                history.append(StorageSnapshot(timestamp: date, usedBytes: mockUsed, freeBytes: mockFree))
            }
            
            if let encoded = try? JSONEncoder().encode(history) {
                UserDefaults.standard.set(encoded, forKey: key)
            }
        }
        
        self.storageHistory = history
        self.calculateForecast()
    }
}
