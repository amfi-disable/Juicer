import SwiftUI
import AppKit

struct vpnprofileview: View {
    @StateObject private var manager = VPNProfileManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            JuicerFeatureHeader(title: "VPN Profile Manager", subtitle: "Inspect and control built-in macOS VPN connections.", icon: "lock.shield", refreshing: manager.refreshing, action: manager.refresh)
            HStack {
                Button("Import JSON") { importProfiles() }
                Button("Export JSON") { exportProfiles() }.disabled(manager.profiles.isEmpty)
                Spacer()
            }
            if !manager.message.isEmpty { Text(manager.message).font(.caption).foregroundStyle(.secondary) }
            List(manager.profiles) { profile in
                HStack {
                    Image(systemName: profile.connected ? "checkmark.circle.fill" : "circle").foregroundStyle(profile.connected ? .green : .secondary)
                    Text(profile.name)
                    Spacer()
                    Button(profile.connected ? "Disconnect" : "Connect") { manager.toggle(profile) }.buttonStyle(.bordered)
                }
            }
            .listStyle(.inset)
        }
        .padding(24)
        .onAppear { manager.refresh() }
    }

    private func exportProfiles() {
        guard let data = manager.exportProfiles() else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "vpn-profiles.json"
        panel.allowedContentTypes = [.json]
        if panel.runModal() == .OK, let url = panel.url { try? data.write(to: url) }
    }

    private func importProfiles() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url, let data = try? Data(contentsOf: url) { manager.importProfiles(data) }
    }
}
