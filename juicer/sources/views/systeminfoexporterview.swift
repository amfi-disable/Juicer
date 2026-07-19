import SwiftUI
import AppKit

struct systeminfoexporterview: View { @State private var message = ""; var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "System Info Exporter", subtitle: "Export a JSON hardware and software report for support tickets.", icon: "doc.badge.gearshape", refreshing: false, action: {}) ; Button("Export JSON Report…") { export() }.buttonStyle(.borderedProminent); Text(message).font(.caption); Spacer() }.padding(24) }
    private func export() { let panel = NSSavePanel(); panel.nameFieldStringValue = "juicer-system-report.json"; guard panel.runModal() == .OK, let url = panel.url, let data = SystemMetricsSupport.run("/usr/sbin/system_profiler", ["-json"])?.data(using: .utf8) else { return }; do { try data.write(to: url); message = "Report exported." } catch { message = error.localizedDescription } }
}
