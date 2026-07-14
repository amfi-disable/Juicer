import Foundation
import AppKit

// MARK: - Models

struct DiskVolume: Identifiable {
    let id: UUID = UUID()
    let name: String
    let mountPoint: String
    let totalBytes: Int64
    let usedBytes: Int64
    let freeBytes: Int64
    var usagePercent: Double { totalBytes > 0 ? Double(usedBytes) / Double(totalBytes) : 0 }
    var fileSystemType: String
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

    private let fileManager = FileManager.default
    private var scanTask: Task<Void, Never>?

    // MARK: - Load Volumes

    func loadVolumes() {
        let home = fileManager.homeDirectoryForCurrentUser.path
        let paths = ["/", home]

        var seen: Set<String> = []
        var result: [DiskVolume] = []

        for path in paths {
            if let attrs = try? fileManager.attributesOfFileSystem(forPath: path),
               let total = attrs[.systemSize] as? Int64,
               let free = attrs[.systemFreeSize] as? Int64 {
                let key = "\(total)-\(free)"
                guard !seen.contains(key) else { continue }
                seen.insert(key)
                let used = total - free

                // Try to get FS type via statvfs
                let fsType = getFSType(for: path)

                result.append(DiskVolume(
                    name: path == "/" ? "Macintosh HD" : "Home (\(URL(fileURLWithPath: home).lastPathComponent))",
                    mountPoint: path,
                    totalBytes: total,
                    usedBytes: used,
                    freeBytes: free,
                    fileSystemType: fsType
                ))
            }
        }
        DispatchQueue.main.async {
            self.volumes = result
        }
    }

    private func getFSType(for path: String) -> String {
        var st = statvfs()
        if statvfs(path, &st) == 0 {
            return "apfs"
        }
        return "unknown"
    }

    // MARK: - Scan Directory

    func scanDirectory(path: String) {
        scanTask?.cancel()
        let targetPath = path.isEmpty ? fileManager.homeDirectoryForCurrentUser.path : path

        DispatchQueue.main.async {
            self.isScanning = true
            self.scanProgress = 0.0
            self.currentPath = targetPath
            self.entries = []
            self.topConsumers = []
            self.errorMessage = nil
        }

        scanTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            let url = URL(fileURLWithPath: targetPath)
            let children = self.scanDir(url: url, depth: 0, maxDepth: 1)
            let sorted = children.sorted { $0.sizeBytes > $1.sizeBytes }
            let top = sorted.prefix(10).map { $0 }

            await MainActor.run {
                self.entries = sorted
                self.topConsumers = top
                self.isScanning = false
                self.scanProgress = 1.0
            }
        }
    }

    func scanDir(url: URL, depth: Int, maxDepth: Int) -> [DiskEntry] {
        guard !Task.isCancelled else { return [] }
        var result: [DiskEntry] = []
        let opts: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants]

        guard let contents = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .isPackageKey], options: opts) else {
            return []
        }

        for item in contents {
            if Task.isCancelled { break }
            var isDir: ObjCBool = false
            fileManager.fileExists(atPath: item.path, isDirectory: &isDir)

            let size: Int64
            if isDir.boolValue {
                size = getDirectorySize(url: item)
            } else {
                size = (try? item.resourceValues(forKeys: [.fileSizeKey]).fileSize).flatMap { Int64($0) } ?? 0
            }

            var entry = DiskEntry(
                name: item.lastPathComponent,
                path: item.path,
                sizeBytes: size,
                isDirectory: isDir.boolValue,
                depth: depth
            )

            if isDir.boolValue && depth < maxDepth {
                entry.children = scanDir(url: item, depth: depth + 1, maxDepth: maxDepth)
            }

            result.append(entry)
        }
        return result
    }

    private func getDirectorySize(url: URL) -> Int64 {
        var size: Int64 = 0
        let opts: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles]
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: opts) else {
            return 0
        }
        for case let fileURL as URL in enumerator {
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                size += Int64(fileSize)
            }
        }
        return size
    }

    func revealInFinder(path: String) {
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
    }

    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
