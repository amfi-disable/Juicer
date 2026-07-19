import SwiftUI

struct firewallview: View {
    @State private var enabled = false
    @State private var message = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Firewall Configuration", subtitle: "Control the macOS Application Firewall and inspect its current state.", icon: "flame", refreshing: false, action: refresh)
            Toggle("Application Firewall", isOn: Binding(get: { enabled }, set: { setFirewall($0) })).toggleStyle(.switch)
            Text("Per-application allow and deny rules remain managed by macOS and require administrator approval.").font(.caption).foregroundStyle(.secondary)
            if !message.isEmpty { Text(message).font(.caption).foregroundStyle(.secondary) }
            Spacer()
        }.padding(24).onAppear(perform: refresh)
    }
    private let tool = "/usr/libexec/ApplicationFirewall/socketfilterfw"
    private func refresh() { DispatchQueue.global().async { let result = SystemMetricsSupport.run(tool, ["--getglobalstate"]) ?? "Unable to query firewall."; DispatchQueue.main.async { enabled = result.contains("enabled") && !result.contains("disabled"); message = result.trimmingCharacters(in: .whitespacesAndNewlines) } } }
    private func setFirewall(_ value: Bool) { DispatchQueue.global().async { let result = SystemMetricsSupport.run(tool, ["--setglobalstate", value ? "on" : "off"]) ?? "Unable to change firewall state."; DispatchQueue.main.async { message = result.trimmingCharacters(in: .whitespacesAndNewlines); refresh() } } }
}
