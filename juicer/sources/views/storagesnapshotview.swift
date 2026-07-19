import SwiftUI

struct storagesnapshotview: View {
    @StateObject private var manager = StorageSnapshotManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Storage Snapshot Manager", subtitle: "Create, inspect, compare, and roll back APFS snapshots.", icon: "clock.arrow.circlepath", refreshing: manager.working, action: manager.refresh)
            HStack {
                TextField("APFS volume", text: $manager.volume).frame(width: 180)
                Button("Refresh") { manager.refresh() }
                Button("Create Snapshot") { manager.create() }.buttonStyle(.borderedProminent)
                Spacer()
                Button("Delete") { manager.delete() }.disabled(manager.selectedID.isEmpty)
                Button("Rollback…") { manager.rollback() }.disabled(manager.selectedID.isEmpty)
            }
            Text("Snapshot deletion and rollback may require administrator approval. Rollback changes the selected volume's state.").font(.caption).foregroundStyle(.orange)
            List(manager.snapshots, selection: $manager.selectedID) { snapshot in HStack { Image(systemName: "camera"); VStack(alignment: .leading) { Text(snapshot.id).font(.system(.body, design: .monospaced)); Text(snapshot.detail).font(.caption).foregroundStyle(.secondary) } } }.listStyle(.inset)
            if !manager.output.isEmpty { ScrollView { Text(manager.output).font(.system(.caption, design: .monospaced)).frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled) }.frame(maxHeight: 140).padding(10).background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8)) }
        }.padding(24).onAppear { manager.refresh() }
    }
}
