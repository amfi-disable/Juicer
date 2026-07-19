import Foundation
import AppKit
import UniformTypeIdentifiers
import Combine

@MainActor
final class AirDropQuickSendManager: ObservableObject {
    @Published var files: [URL] = []
    @Published var isTargeted = false
    @Published var message = "Drop files here to prepare an AirDrop."

    var canSend: Bool { !files.isEmpty && NSSharingService(named: .sendViaAirDrop) != nil }

    func add(providers: [NSItemProvider]) -> Bool {
        let accepted = providers.filter { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }
        guard !accepted.isEmpty else { message = "Only files and folders can be sent with AirDrop."; return false }
        for provider in accepted {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { [weak self] item, error in
                guard let self, error == nil else { return }
                let url: URL?
                if let value = item as? URL { url = value }
                else if let value = item as? NSURL { url = value as URL }
                else if let value = item as? Data { url = URL(dataRepresentation: value, relativeTo: nil) }
                else { url = nil }
                guard let url else { return }
                Task { @MainActor in
                    if !self.files.contains(url) { self.files.append(url); self.message = "\(self.files.count) item(s) ready to send." }
                }
            }
        }
        return true
    }

    func send() {
        guard let service = NSSharingService(named: .sendViaAirDrop), !files.isEmpty else { message = "AirDrop is unavailable on this Mac or no files were selected."; return }
        service.perform(withItems: files)
        message = "AirDrop share sheet opened."
    }

    func clear() {
        files.removeAll()
        message = "Drop files here to prepare an AirDrop."
    }
}
