import SwiftUI

struct duplicatefileview: View {
    @StateObject private var manager = DuplicateFileManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            JuicerFeatureHeader(title: "Duplicate File Finder", subtitle: "Match files by size and SHA-256 content hash.", icon: "doc.on.doc", refreshing: manager.isScanning, action: manager.scan)
            HStack { Text(manager.message).font(.caption).foregroundStyle(.secondary); Spacer(); Button("Move Selected to Trash", role: .destructive) { manager.trashSelected() }.disabled(!manager.files.contains(where: \.selected)) }
            List(manager.files) { file in
                HStack {
                    Toggle("", isOn: Binding(get: { file.selected }, set: { value in if let index = manager.files.firstIndex(where: { $0.id == file.id }) { manager.files[index].selected = value } })).labelsHidden()
                    Image(systemName: "doc.fill").foregroundStyle(.secondary)
                    VStack(alignment: .leading) { Text(file.url.lastPathComponent); Text(file.url.path).font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle) }
                    Spacer()
                    Text(SystemMetricsSupport.bytes(UInt64(file.size))).monospacedDigit()
                }
            }
            .listStyle(.inset)
        }
        .padding(24)
        .onAppear { manager.scan() }
    }
}
