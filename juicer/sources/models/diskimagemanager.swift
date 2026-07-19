import Foundation
import Combine

struct DiskImage: Identifiable {
    let id = UUID()
    let url: URL
    var mounted = false
}

final class DiskImageManager: ObservableObject {
    @Published var images: [DiskImage] = []
    @Published var selectedURL: URL?
    @Published var message = ""
    @Published var working = false

    func scan() {
        let roots = [FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads"), FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")]
        let urls = roots.flatMap { (try? FileManager.default.contentsOfDirectory(at: $0, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? [] }.filter { ["dmg", "iso", "sparsebundle"].contains($0.pathExtension.lowercased()) }
        images = urls.map { DiskImage(url: $0) }
    }

    func run(_ arguments: [String], action: String) {
        guard let selectedURL else { return }
        working = true
        DispatchQueue.global().async {
            let output = SystemMetricsSupport.run("/usr/bin/hdiutil", arguments + [selectedURL.path]) ?? ""
            DispatchQueue.main.async { self.message = output.split(separator: "\n").last.map(String.init) ?? "\(action) completed."; self.working = false; self.scan() }
        }
    }

    func mount() { run(["attach"], action: "Mount") }
    func verify() { run(["verify"], action: "Verification") }
    func convert(to format: String, destination: URL) {
        guard let selectedURL else { return }
        working = true
        DispatchQueue.global().async { let output = SystemMetricsSupport.run("/usr/bin/hdiutil", ["convert", selectedURL.path, "-format", format, "-o", destination.path]) ?? ""; DispatchQueue.main.async { self.message = output.split(separator: "\n").last.map(String.init) ?? "Conversion completed."; self.working = false } }
    }

    func create(from folder: URL, destination: URL) {
        working = true
        DispatchQueue.global().async { let output = SystemMetricsSupport.run("/usr/bin/hdiutil", ["create", destination.path, "-srcfolder", folder.path, "-format", "UDZO"]) ?? ""; DispatchQueue.main.async { self.message = output.split(separator: "\n").last.map(String.init) ?? "Disk image created."; self.working = false; self.scan() } }
    }
}
