import SwiftUI

struct desktopiconstoggleview: View {
    @State private var visible = true
    @State private var message = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Desktop Icons Toggle", subtitle: "Show or hide Finder desktop icons with one click.", icon: "macwindow", refreshing: false, action: refresh)
            Toggle("Show desktop icons", isOn: Binding(get: { visible }, set: { setVisible($0) })).toggleStyle(.switch)
            if !message.isEmpty { Text(message).font(.caption).foregroundStyle(.secondary) }
            Spacer()
        }.padding(24).onAppear(perform: refresh)
    }
    private func refresh() { let output = SystemMetricsSupport.run("/usr/bin/defaults", ["read", "com.apple.finder", "CreateDesktop"]) ?? "1"; visible = !output.contains("0") }
    private func setVisible(_ value: Bool) { _ = SystemMetricsSupport.run("/usr/bin/defaults", ["write", "com.apple.finder", "CreateDesktop", "-bool", value ? "true" : "false"]); _ = SystemMetricsSupport.run("/usr/bin/killall", ["Finder"]); visible = value; message = "Finder restarted with desktop icons \(value ? "shown" : "hidden")." }
}
