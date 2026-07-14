import Foundation

struct LargeFileItem: Identifiable, Hashable {
    let id: UUID = UUID()
    let url: URL
    let size: Int64
    let modificationDate: Date
    var isSelected: Bool
    
    var name: String { url.lastPathComponent }
    var path: String { url.path }
}

class LargeFilesManager: ObservableObject {
    @Published var largeFiles: [LargeFileItem] = []
    @Published var isScanning = false
    @Published var isTrashing = false
    @Published var sizeThresholdMB: Double = 100.0
    @Published var ageThresholdMonths: Int = 12
    
    private let fileManager = FileManager.default
    
    func startScan() {
        self.isScanning = true
        self.largeFiles = []
        AppLogger.shared.log("Scanning Downloads, Documents, and Desktop folders for large or old files...")
        
        let sizeLimit = Int64(sizeThresholdMB) * 1024 * 1024
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .month, value: -ageThresholdMonths, to: Date()) ?? Date.distantPast
        
        Task.detached(priority: .userInitiated) {
            let home = FileManager.default.homeDirectoryForCurrentUser
            let searchDirectories = [
                home.appendingPathComponent("Downloads"),
                home.appendingPathComponent("Documents"),
                home.appendingPathComponent("Desktop")
            ]
            
            var discovered: [LargeFileItem] = []
            let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey]
            
            for directory in searchDirectories {
                guard self.fileManager.fileExists(atPath: directory.path) else { continue }
                
                guard let enumerator = self.fileManager.enumerator(
                    at: directory,
                    includingPropertiesForKeys: keys,
                    options: [.skipsPackageDescendants, .skipsHiddenFiles]
                ) else { continue }
                
                for case let fileURL as URL in enumerator {
                    guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(keys)),
                          let isFile = resourceValues.isRegularFile, isFile,
                          let fileSize = resourceValues.fileSize,
                          let modDate = resourceValues.contentModificationDate
                    else { continue }
                    
                    let size = Int64(fileSize)
                    
                    // Match either larger than size threshold OR older than age threshold
                    if size >= sizeLimit || modDate < cutoffDate {
                        discovered.append(LargeFileItem(
                            url: fileURL,
                            size: size,
                            modificationDate: modDate,
                            isSelected: false
                        ))
                    }
                }
            }
            
            // Sort by size descending
            let sorted = discovered.sorted(by: { $0.size > $1.size })
            
            await MainActor.run {
                self.largeFiles = sorted
                self.isScanning = false
                AppLogger.shared.log("Found \(sorted.count) large or old files matching criteria.")
            }
        }
    }
    
    func trashSelectedItems(completion: @escaping (Bool) -> Void) {
        self.isTrashing = true
        let itemsToTrash = largeFiles.filter { $0.isSelected }
        
        AppLogger.shared.log("Moving \(itemsToTrash.count) selected large files to Trash...")
        
        Task.detached(priority: .userInitiated) {
            var success = true
            
            for item in itemsToTrash {
                do {
                    if self.fileManager.fileExists(atPath: item.path) {
                        try self.fileManager.trashItem(at: item.url, resultingItemURL: nil)
                    }
                } catch {
                    AppLogger.shared.log("Failed to trash file \(item.name): \(error.localizedDescription)")
                    success = false
                }
            }
            
            await MainActor.run {
                self.isTrashing = false
                self.startScan() // Refresh scan
                completion(success)
            }
        }
    }
}
