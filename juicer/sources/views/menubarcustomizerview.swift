import SwiftUI

struct menubarcustomizerview: View {
    @State private var items = ["Juicer", "Clipboard", "Status", "Scripts"]
    @State private var enabled = Set(["Juicer", "Status"])
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Menu-Bar Customizer", subtitle: "Choose which Juicer companions are enabled and arrange their order.", icon: "menubar.rectangle", refreshing: false, action: {})
            List { ForEach(items, id: \.self) { item in HStack { Image(systemName: "line.3.horizontal"); Text(item); Spacer(); Toggle("", isOn: Binding(get: { enabled.contains(item) }, set: { if $0 { enabled.insert(item) } else { enabled.remove(item) } })).labelsHidden() }.padding(.vertical, 4) }.onMove { items.move(fromOffsets: $0, toOffset: $1) } }
            Text("Menu-bar registration is applied when each companion launches. These preferences are stored locally.").font(.caption).foregroundStyle(.secondary)
        }.padding(24)
    }
}
