import SwiftUI

struct emptyfolderview: View {
    @StateObject private var manager = EmptyFolderManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            JuicerFeatureHeader(title: "Empty Folder Cleaner", subtitle: "Find empty directories in common user folders and move them to Trash safely.", icon: "folder.badge.minus", refreshing: manager.isScanning, action: manager.scan)
            HStack { Text(manager.message).font(.caption).foregroundStyle(.secondary); Spacer(); Button("Move Selected to Trash", role: .destructive) { manager.trashSelected() }.disabled(!manager.folders.contains(where: \.selected)) }
            List(manager.folders) { folder in
                HStack {
                    Toggle("", isOn: Binding(get: { folder.selected }, set: { value in if let index = manager.folders.firstIndex(where: { $0.id == folder.id }) { manager.folders[index].selected = value } })).labelsHidden()
                    Image(systemName: "folder").foregroundStyle(.secondary)
                    Text(folder.url.path).font(.system(.body, design: .monospaced)).lineLimit(1).truncationMode(.middle)
                }
            }
            .listStyle(.inset)
        }
        .padding(24)
        .onAppear { manager.scan() }
    }
}
