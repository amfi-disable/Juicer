import SwiftUI
import AppKit

struct symboliclinkview: View {
    @StateObject private var manager = SymbolicLinkManager()
    @State private var pendingDelete: LinkEntry?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Symbolic Link Manager", subtitle: "Create, validate, and remove symbolic or hard links.", icon: "link", refreshing: false, action: manager.scan)
            HStack {
                Button("Choose Target…") { chooseTarget() }
                Button("Choose Link Folder…") { chooseFolder() }
                TextField("Link name", text: $manager.linkName).frame(width: 160)
                Toggle("Hard link", isOn: $manager.hardLink).toggleStyle(.checkbox)
                Button("Create") { manager.create() }.buttonStyle(.borderedProminent)
            }
            if let folder = manager.folder { Text("Folder: \(folder.path)").font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle) }
            if let target = manager.selectedTarget { Text("Target: \(target.path)").font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle) }
            if !manager.message.isEmpty { Text(manager.message).font(.caption).foregroundStyle(.secondary) }
            List(manager.entries) { entry in
                HStack { Image(systemName: entry.valid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill").foregroundStyle(entry.valid ? .green : .orange); VStack(alignment: .leading) { Text(entry.url.lastPathComponent); Text(entry.target).font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle) }; Spacer(); Button("Delete") { pendingDelete = entry }.buttonStyle(.borderless) }
            }.listStyle(.inset)
        }.padding(24).alert("Delete link?", isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })) { Button("Cancel", role: .cancel) { pendingDelete = nil }; Button("Delete", role: .destructive) { if let pendingDelete { manager.delete(pendingDelete) }; pendingDelete = nil } } message: { Text("The target file will not be removed.") }
    }

    private func chooseTarget() { let panel = NSOpenPanel(); if panel.runModal() == .OK { manager.selectedTarget = panel.url } }
    private func chooseFolder() { let panel = NSOpenPanel(); panel.canChooseDirectories = true; panel.canChooseFiles = false; if panel.runModal() == .OK { manager.folder = panel.url; manager.scan() } }
}
