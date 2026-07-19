import Foundation
import Combine

final class ArchiveUtilityManager: ObservableObject {
    @Published var inputURL: URL?
    @Published var message = "Drop an archive or folder here."
    @Published var working = false

    func setInput(_ url: URL) { inputURL = url; message = "Ready: \(url.lastPathComponent)" }

    func extract(to destination: URL) {
        guard let inputURL else { return }
        working = true
        let isZip = inputURL.pathExtension.lowercased() == "zip"
        let arguments = isZip ? ["-x", "-k", inputURL.path, destination.path] : ["-xf", inputURL.path, "-C", destination.path]
        let command = isZip ? "/usr/bin/ditto" : "/usr/bin/tar"
        DispatchQueue.global().async {
            let result = SystemMetricsSupport.run(command, arguments)
            DispatchQueue.main.async { self.message = result?.isEmpty == false ? result! : "Extracted \(inputURL.lastPathComponent)."; self.working = false }
        }
    }

    func createZip(at destination: URL) {
        guard let inputURL else { return }
        working = true
        DispatchQueue.global().async {
            let result = SystemMetricsSupport.run("/usr/bin/ditto", ["-c", "-k", "--sequesterRsrc", "--keepParent", inputURL.path, destination.path])
            DispatchQueue.main.async { self.message = result?.isEmpty == false ? result! : "Created \(destination.lastPathComponent)."; self.working = false }
        }
    }
}
