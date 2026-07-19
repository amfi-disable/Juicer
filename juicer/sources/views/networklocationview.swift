import SwiftUI

struct networklocationview: View {
    @StateObject private var manager = NetworkLocationManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            JuicerFeatureHeader(title: "Network Location Manager", subtitle: "Create and switch macOS network service configurations.", icon: "network", refreshing: manager.refreshing, action: manager.refresh)
            HStack {
                TextField("New location name", text: $manager.newName).textFieldStyle(.roundedBorder)
                Button("Create") { manager.create() }.buttonStyle(.borderedProminent)
            }
            if !manager.message.isEmpty { Text(manager.message).font(.caption).foregroundStyle(.secondary) }
            List(manager.locations) { location in
                HStack {
                    Image(systemName: location.current ? "checkmark.circle.fill" : "circle").foregroundStyle(location.current ? .green : .secondary)
                    Text(location.name)
                    Spacer()
                    if !location.current { Button("Switch") { manager.switchTo(location) }.buttonStyle(.bordered) }
                    Button(role: .destructive) { manager.delete(location) } label: { Image(systemName: "trash") }.disabled(location.current)
                }
            }
            .listStyle(.inset)
        }
        .padding(24)
        .onAppear { manager.refresh() }
    }
}
