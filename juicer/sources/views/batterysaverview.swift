import SwiftUI

struct batterysaverview: View {
    @State private var enabled = false
    @State private var message = ""
    var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "Battery-Saver Mode", subtitle: "Toggle low-power visual preferences when running on battery.", icon: "battery.50percent", refreshing: false, action: {}) ; Toggle("Battery-saver preferences", isOn: Binding(get: { enabled }, set: { apply($0) })).toggleStyle(.switch); Text("This adjusts Reduce Motion and Reduce Transparency. Hardware power controls remain managed by macOS.").font(.caption).foregroundStyle(.secondary); Text(message).font(.caption); Spacer() }.padding(24) }
    private func apply(_ value: Bool) { enabled = value; _ = SystemMetricsSupport.run("/usr/bin/defaults", ["write", "com.apple.universalaccess", "reduceMotion", "-bool", value ? "true" : "false"]); _ = SystemMetricsSupport.run("/usr/bin/defaults", ["write", "com.apple.universalaccess", "reduceTransparency", "-bool", value ? "true" : "false"]); message = value ? "Battery-saver preferences enabled." : "Battery-saver preferences disabled." }
}
