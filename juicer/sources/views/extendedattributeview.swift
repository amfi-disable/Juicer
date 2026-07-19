import SwiftUI
import AppKit

struct extendedattributeview: View {
    @StateObject private var manager = ExtendedAttributeManager()
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Extended Attributes", subtitle: "View and edit com.apple.*, quarantine, and other xattrs.", icon: "tag", refreshing: false, action: manager.refresh)
            HStack { Button("Choose Path…") { choose() }; if let url = manager.selectedURL { Text(url.path).font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle) } }
            HStack { TextField("Attribute name", text: $manager.attributeName).textFieldStyle(.roundedBorder); TextField("Value", text: $manager.attributeValue).textFieldStyle(.roundedBorder); Button("Write") { manager.write() }.buttonStyle(.borderedProminent) }
            Text(manager.message).font(.caption).foregroundStyle(.secondary)
            List(manager.attributes) { attribute in HStack { VStack(alignment: .leading) { Text(attribute.name).font(.system(.body, design: .monospaced)); Text(attribute.value).font(.caption).foregroundStyle(.secondary).lineLimit(2) }; Spacer(); Button(role: .destructive) { manager.delete(attribute) } label: { Image(systemName: "trash") } } }.listStyle(.inset)
        }.padding(24)
    }
    private func choose() { let panel = NSOpenPanel(); panel.canChooseFiles = true; panel.canChooseDirectories = true; if panel.runModal() == .OK, let url = panel.url { manager.select(url) } }
}
