import SwiftUI
import AppKit

struct metadataeditorview: View {
    @StateObject private var manager = MetadataEditorManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Metadata Editor", subtitle: "Apply EXIF, IPTC, XMP, ID3, PDF, or Office tags to multiple files.", icon: "tag", refreshing: manager.working, action: {})
            HStack {
                Button("Choose Files…") { chooseFiles() }
                TextField("Tag name", text: $manager.key).frame(width: 160)
                TextField("Value", text: $manager.value)
                Button("Apply to All") { manager.apply() }.buttonStyle(.borderedProminent).disabled(manager.working || manager.files.isEmpty)
            }
            if manager.toolPath == nil { Text("Install exiftool with Homebrew to enable metadata reads and writes.").font(.caption).foregroundStyle(.orange) }
            if !manager.message.isEmpty { Text(manager.message).font(.caption).foregroundStyle(.secondary) }
            List(manager.files) { file in Label(file.url.path, systemImage: "doc.text").lineLimit(1).truncationMode(.middle) }.listStyle(.inset)
        }.padding(24)
    }

    private func chooseFiles() { let panel = NSOpenPanel(); panel.allowsMultipleSelection = true; if panel.runModal() == .OK { manager.add(panel.urls) } }
}
