import SwiftUI
import AppKit

struct diskimageview: View {
    @StateObject private var manager = DiskImageManager()
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Disk Image Manager", subtitle: "Mount, verify, convert, and create DMG/ISO-style images.", icon: "externaldrive.badge.timemachine", refreshing: manager.working, action: manager.scan)
            HStack { Button("Choose Image") { chooseImage() }; Button("Create from Folder…") { createImage() }; Spacer() }
            if let selected = manager.selectedURL { Text(selected.path).font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle); HStack { Button("Mount") { manager.mount() }; Button("Verify") { manager.verify() }; Button("Convert to UDZO…") { convertImage() } } }
            if !manager.message.isEmpty { Text(manager.message).font(.caption).foregroundStyle(.secondary) }
            List(manager.images) { image in Button { manager.selectedURL = image.url } label: { HStack { Image(systemName: "externaldrive"); Text(image.url.lastPathComponent); Spacer(); Text(image.url.path).font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle) } }.buttonStyle(.plain) }
            .listStyle(.inset)
        }.padding(24).onAppear { manager.scan() }
    }
    private func chooseImage() { let panel = NSOpenPanel(); panel.allowedContentTypes = [.diskImage]; if panel.runModal() == .OK, let url = panel.url { manager.selectedURL = url } }
    private func createImage() { let open = NSOpenPanel(); open.canChooseDirectories = true; open.canChooseFiles = false; guard open.runModal() == .OK, let folder = open.url else { return }; let save = NSSavePanel(); save.nameFieldStringValue = "image.dmg"; if save.runModal() == .OK, let url = save.url { manager.create(from: folder, destination: url) } }
    private func convertImage() { let save = NSSavePanel(); save.nameFieldStringValue = "converted.dmg"; if save.runModal() == .OK, let url = save.url { manager.convert(to: "UDZO", destination: url) } }
}
