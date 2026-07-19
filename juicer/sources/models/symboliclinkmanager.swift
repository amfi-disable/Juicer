import Foundation
import Combine

struct LinkEntry: Identifiable {
    let id = UUID()
    let url: URL
    let isSymbolic: Bool
    let target: String
    var valid: Bool
}

final class SymbolicLinkManager: ObservableObject {
    @Published var folder: URL?
    @Published var entries: [LinkEntry] = []
    @Published var selectedTarget: URL?
    @Published var linkName = ""
    @Published var hardLink = false
    @Published var message = ""

    func scan() {
        guard let folder else { entries = []; return }
        let urls = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.isSymbolicLinkKey, .isRegularFileKey], options: [])) ?? []
        entries = urls.compactMap { url in
            let values = try? url.resourceValues(forKeys: [.isSymbolicLinkKey])
            guard values?.isSymbolicLink == true else { return nil }
            let target = (try? FileManager.default.destinationOfSymbolicLink(atPath: url.path)) ?? ""
            return LinkEntry(url: url, isSymbolic: true, target: target, valid: FileManager.default.fileExists(atPath: url.resolvingSymlinksInPath().path))
        }
    }

    func create() {
        guard let folder, let selectedTarget, !linkName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { message = "Choose a target, folder, and link name first."; return }
        let destination = folder.appendingPathComponent(linkName)
        do {
            if hardLink { try FileManager.default.linkItem(at: selectedTarget, to: destination) } else { try FileManager.default.createSymbolicLink(at: destination, withDestinationURL: selectedTarget) }
            message = "Created \(destination.lastPathComponent)."
            scan()
        } catch { message = error.localizedDescription }
    }

    func delete(_ entry: LinkEntry) {
        do { try FileManager.default.removeItem(at: entry.url); message = "Deleted \(entry.url.lastPathComponent)."; scan() } catch { message = error.localizedDescription }
    }
}
