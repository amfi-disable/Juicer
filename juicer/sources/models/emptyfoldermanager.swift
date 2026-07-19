import Foundation
import Combine

struct EmptyFolder: Identifiable {
    let id = UUID()
    let url: URL
    var selected = true
}

final class EmptyFolderManager: ObservableObject {
    @Published var folders: [EmptyFolder] = []
    @Published var isScanning = false
    @Published var message = ""

    func scan() {
        isScanning = true
        let roots = ["Downloads", "Documents", "Desktop"].map { FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent($0) }
        DispatchQueue.global(qos: .userInitiated).async {
            var result: [EmptyFolder] = []
            for root in roots {
                guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { continue }
                for case let url as URL in enumerator {
                    guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey]), values.isDirectory == true, values.isSymbolicLink != true else { continue }
                    if let contents = try? FileManager.default.contentsOfDirectory(atPath: url.path), contents.isEmpty { result.append(EmptyFolder(url: url)) }
                }
            }
            DispatchQueue.main.async { self.folders = result.sorted { $0.url.path < $1.url.path }; self.message = "Found \(result.count) empty folders."; self.isScanning = false }
        }
    }

    func trashSelected() {
        let selected = folders.filter(\.selected)
        for folder in selected { try? FileManager.default.trashItem(at: folder.url, resultingItemURL: nil) }
        scan()
    }
}
