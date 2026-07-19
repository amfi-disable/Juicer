import SwiftUI

struct swapmanagerview: View {
    @StateObject private var manager = SwapManager()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                JuicerFeatureHeader(title: "Swap Manager", subtitle: "Inspect swapfile usage and control macOS dynamic paging.", icon: "arrow.left.arrow.right", refreshing: manager.refreshing, action: manager.refresh)
                HStack {
                    JuicerMetricTile(title: "Used", value: SystemMetricsSupport.bytes(manager.reading.used), detail: "active swap", color: .orange)
                    JuicerMetricTile(title: "Free", value: SystemMetricsSupport.bytes(manager.reading.free), detail: "available swap", color: .green)
                    JuicerMetricTile(title: "Total", value: SystemMetricsSupport.bytes(manager.reading.total), detail: "allocated swap", color: .blue)
                }
                Toggle("Dynamic paging enabled", isOn: Binding(get: { manager.reading.enabled }, set: { manager.setEnabled($0) }))
                    .disabled(manager.changing)
                if !manager.message.isEmpty { Text(manager.message).font(.caption).foregroundStyle(.secondary) }
                Text(manager.reading.detail).font(.system(.caption, design: .monospaced)).foregroundStyle(.secondary)
                Text("Disabling swap can destabilize macOS when physical memory is exhausted and requires administrator approval.").font(.caption).foregroundStyle(.secondary)
            }
            .padding(24)
        }
        .onAppear { manager.refresh() }
    }
}
