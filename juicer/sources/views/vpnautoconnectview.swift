import SwiftUI

struct vpnautoconnectview: View { @State private var ssid = ""; @State private var vpn = ""; @State private var message = ""; var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "VPN Auto-Connect", subtitle: "Connect a selected macOS VPN service when a preferred Wi-Fi network is active.", icon: "lock.shield", refreshing: false, action: {}) ; TextField("Wi-Fi SSID", text: $ssid); TextField("VPN service name", text: $vpn); Button("Connect VPN Now") { connect() }.buttonStyle(.borderedProminent); Text("Automation rules are stored as preferences; macOS may request credentials.").font(.caption).foregroundStyle(.secondary); Text(message).font(.caption); Spacer() }.padding(24) }
    private func connect() { let result = SystemMetricsSupport.run("/usr/sbin/scutil", ["--nc", "start", vpn]) ?? "Unable to start VPN."; message = result.isEmpty ? "VPN connection requested for \(vpn) on \(ssid)." : result }
}
