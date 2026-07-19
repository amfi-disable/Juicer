import SwiftUI

struct downloadorganizerview: View {
    @StateObject private var manager = DownloadOrganizer()
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            JuicerFeatureHeader(title: "Download Folder Organizer", subtitle: "Preview rules that sort Downloads into type and month folders.", icon: "folder.badge.gearshape", refreshing: manager.isScanning || manager.isOrganizing, action: manager.scan)
            HStack { Text(manager.message).font(.caption).foregroundStyle(.secondary); Spacer(); Button("Organize Selected") { manager.organize() }.buttonStyle(.borderedProminent).disabled(manager.isOrganizing || !manager.items.contains(where: \.selected)) }
            List(manager.items) { item in
                HStack {
                    Toggle("", isOn: Binding(get: { item.selected }, set: { value in if let index = manager.items.firstIndex(where: { $0.id == item.id }) { manager.items[index].selected = value } })).labelsHidden()
                    Image(systemName: "doc").foregroundStyle(.secondary)
                    Text(item.url.lastPathComponent).lineLimit(1)
                    Spacer()
                    Text("\(item.category.rawValue) / \(item.month)").font(.caption).foregroundStyle(.secondary)
                }
            }.listStyle(.inset)
        }.padding(24).onAppear { manager.scan() }
    }
}
