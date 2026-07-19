import Foundation
import Combine

struct MetadataInput: Identifiable {
    let id = UUID()
    let url: URL
}

final class MetadataEditorManager: ObservableObject {
    @Published var files: [MetadataInput] = []
    @Published var key = "Comment"
    @Published var value = ""
    @Published var message = ""
    @Published var working = false

    var toolPath: String? { ["/opt/homebrew/bin/exiftool", "/usr/local/bin/exiftool", "/usr/bin/exiftool"].first { FileManager.default.isExecutableFile(atPath: $0) } }

    func add(_ urls: [URL]) { files = urls.map { MetadataInput(url: $0) } }

    func apply() {
        guard let toolPath, !files.isEmpty, !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { message = "Select files, enter a tag, and ensure exiftool is installed."; return }
        working = true
        let selected = files
        let tag = key
        let newValue = value
        DispatchQueue.global(qos: .userInitiated).async {
            var changed = 0
            for file in selected where SystemMetricsSupport.run(toolPath, ["-overwrite_original", "-\(tag)=\(newValue)", file.url.path]) != nil { changed += 1 }
            DispatchQueue.main.async { self.working = false; self.message = "Updated \(changed) of \(selected.count) file(s)." }
        }
    }
}
