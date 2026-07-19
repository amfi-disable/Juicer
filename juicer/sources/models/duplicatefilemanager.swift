import Foundation
import Combine

struct DuplicateFile: Identifiable {
    let id = UUID()
    let url: URL
    let size: Int64
    let hash: String
    var selected = false
}

final class DuplicateFileManager: ObservableObject {
    @Published var files: [DuplicateFile] = []
    @Published var isScanning = false
    @Published var message = ""

    func scan() {
        isScanning = true
        message = "Scanning user folders for matching file content…"
        let roots = ["Downloads", "Documents", "Desktop"].map { FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent($0) }
        DispatchQueue.global(qos: .userInitiated).async {
            var candidates: [URL: Int64] = [:]
            let keys: Set<URLResourceKey> = [.isRegularFileKey, .fileSizeKey]
            for root in roots {
                guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: Array(keys), options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { continue }
                for case let url as URL in enumerator {
                    guard let values = try? url.resourceValues(forKeys: keys), values.isRegularFile == true, let size = values.fileSize, size > 0 else { continue }
                    candidates[url] = Int64(size)
                }
            }
            var bySize = [Int64: [URL]]()
            candidates.forEach { bySize[$0.value, default: []].append($0.key) }
            var duplicates: [DuplicateFile] = []
            for (size, urls) in bySize where urls.count > 1 {
                var byHash = [String: [URL]]()
                for url in urls {
                    guard let hash = SystemMetricsSupport.run("/usr/bin/shasum", ["-a", "256", url.path])?.split(separator: " ").first else { continue }
                    byHash[String(hash), default: []].append(url)
                }
                for (hash, matches) in byHash where matches.count > 1 {
                    duplicates.append(contentsOf: matches.map { DuplicateFile(url: $0, size: size, hash: hash) })
                }
            }
            DispatchQueue.main.async {
                self.files = duplicates.sorted { $0.size > $1.size }
                self.message = "Found \(duplicates.count) files in duplicate groups."
                self.isScanning = false
            }
        }
    }

    func trashSelected() {
        let selected = files.filter(\.selected)
        for file in selected { try? FileManager.default.trashItem(at: file.url, resultingItemURL: nil) }
        scan()
    }
}
