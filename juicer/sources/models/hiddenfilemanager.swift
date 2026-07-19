import Foundation

struct HiddenFileItem: Identifiable, Hashable {
    let id: UUID = UUID()
    let url: URL
    let size: Int64
    let isDirectory: Bool
    let isHiddenByFlag: Bool
    let isHiddenByName: Bool
    
    var name: String { url.lastPathComponent }
    var path: String { url.path }
}

class HiddenFileManager: ObservableObject {
    @Published var hiddenItems: [HiddenFileItem] = []
    @Published var isScanning = false
    @Published var selectedPath: String = ""
    @Published var showAllFiles = false
    
    private let fileManager = FileManager.default

    init() { refreshGlobalVisibility() }

    func refreshGlobalVisibility() {
        showAllFiles = (SystemMetricsSupport.run("/usr/bin/defaults", ["read", "com.apple.finder", "AppleShowAllFiles"]) ?? "").contains("1") || (SystemMetricsSupport.run("/usr/bin/defaults", ["read", "com.apple.finder", "AppleShowAllFiles"]) ?? "").contains("true")
    }

    func toggleGlobalVisibility(_ visible: Bool) {
        _ = SystemMetricsSupport.run("/usr/bin/defaults", ["write", "com.apple.finder", "AppleShowAllFiles", "-bool", visible ? "true" : "false"])
        _ = SystemMetricsSupport.run("/usr/bin/killall", ["Finder"])
        showAllFiles = visible
    }
    
    func startScan(for directoryPath: String) {
        let cleanPath = directoryPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanPath.isEmpty else { return }
        
        let path = cleanPath.hasPrefix("~") ?
            cleanPath.replacingOccurrences(of: "~", with: fileManager.homeDirectoryForCurrentUser.path) : cleanPath
        
        let url = URL(fileURLWithPath: path)
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue else {
            AppLogger.shared.log("Error: '\(directoryPath)' is not a valid directory.")
            return
        }
        
        self.selectedPath = url.path
        self.isScanning = true
        self.hiddenItems = []
        AppLogger.shared.log("Scanning directory '\(url.lastPathComponent)' for hidden files...")
        
        Task.detached(priority: .userInitiated) {
            var found: [HiddenFileItem] = []
            
            let keys: [URLResourceKey] = [.isHiddenKey, .isDirectoryKey, .fileSizeKey]
            guard let enumerator = self.fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: keys,
                options: [.skipsPackageDescendants]
            ) else {
                await MainActor.run { self.isScanning = false }
                return
            }
            
            for case let fileURL as URL in enumerator {
                let resourceValues = try? fileURL.resourceValues(forKeys: Set(keys))
                let name = fileURL.lastPathComponent
                
                let isHiddenByName = name.hasPrefix(".")
                let isHiddenByFlag = resourceValues?.isHidden ?? false
                let isDirectory = resourceValues?.isDirectory ?? false
                
                if isHiddenByName || isHiddenByFlag {
                    // Calculate size
                    var size: Int64 = 0
                    if isDirectory {
                        size = self.calculateDirectorySize(at: fileURL)
                        // If it's a hidden directory (like .git), skip enumerating its children to avoid duplicate sub-items in the list
                        enumerator.skipDescendants()
                    } else {
                        size = Int64(resourceValues?.fileSize ?? 0)
                    }
                    
                    found.append(HiddenFileItem(
                        url: fileURL,
                        size: size,
                        isDirectory: isDirectory,
                        isHiddenByFlag: isHiddenByFlag,
                        isHiddenByName: isHiddenByName
                    ))
                }
            }
            
            let sorted = found.sorted(by: { $0.size > $1.size })
            
            await MainActor.run {
                self.hiddenItems = sorted
                self.isScanning = false
                AppLogger.shared.log("Scan finished. Discovered \(sorted.count) hidden files/directories.")
            }
        }
    }
    
    func toggleVisibility(for item: HiddenFileItem, completion: @escaping (Bool) -> Void) {
        AppLogger.shared.log("Toggling visibility flag for '\(item.name)'...")
        
        let newFlag = item.isHiddenByFlag ? "nohidden" : "hidden"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/chflags")
        process.arguments = [newFlag, item.path]
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let success = process.terminationStatus == 0
            if success {
                AppLogger.shared.log("Successfully set '\(newFlag)' on \(item.name).")
                // Refresh list
                startScan(for: selectedPath)
            } else {
                AppLogger.shared.log("chflags failed to apply visibility toggle.")
            }
            completion(success)
        } catch {
            AppLogger.shared.log("Failed to run chflags: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    func trashItem(_ item: HiddenFileItem, completion: @escaping (Bool) -> Void) {
        AppLogger.shared.log("Moving hidden item to Trash: \(item.name)...")
        
        do {
            try fileManager.trashItem(at: item.url, resultingItemURL: nil)
            AppLogger.shared.log("Successfully moved \(item.name) to Trash.")
            // Remove locally
            if let index = hiddenItems.firstIndex(where: { $0.id == item.id }) {
                hiddenItems.remove(at: index)
            }
            completion(true)
        } catch {
            AppLogger.shared.log("Failed to move to Trash: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    private func calculateDirectorySize(at url: URL) -> Int64 {
        var size: Int64 = 0
        let keys: [URLResourceKey] = [.fileSizeKey, .isDirectoryKey]
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: []
        ) else { return 0 }
        
        for case let fileURL as URL in enumerator {
            if let resourceValues = try? fileURL.resourceValues(forKeys: Set(keys)) {
                let isDirectory = resourceValues.isDirectory ?? false
                if !isDirectory {
                    size += Int64(resourceValues.fileSize ?? 0)
                }
            }
        }
        
        return size
    }
}
