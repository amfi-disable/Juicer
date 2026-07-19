import SwiftUI

struct cpumemorymonitorview: View {
    @StateObject private var manager = CPUMemoryMonitorManager()
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                JuicerFeatureHeader(title: "CPU & Memory Monitor", subtitle: "Real-time processor load, memory pressure, swap, and load averages.", icon: "waveform.path.ecg", refreshing: manager.isRefreshing, action: manager.refresh)
                HStack(spacing: 12) {
                    JuicerMetricTile(title: "CPU Usage", value: SystemMetricsSupport.percent(manager.cpuPercent), detail: "\(ProcessInfo.processInfo.processorCount) logical cores", color: manager.cpuPercent > 85 ? .red : .blue)
                    JuicerMetricTile(title: "Memory Used", value: SystemMetricsSupport.percent(Double(manager.memoryUsedBytes) / Double(max(1, manager.memoryTotalBytes)) * 100), detail: "\(SystemMetricsSupport.formatBytes(manager.memoryUsedBytes)) of \(SystemMetricsSupport.formatBytes(manager.memoryTotalBytes))", color: .purple)
                    JuicerMetricTile(title: "Swap Used", value: SystemMetricsSupport.formatBytes(manager.swapUsedBytes), detail: "Pressure: \(manager.memoryPressure.capitalized)", color: manager.memoryPressure == "critical" ? .red : .orange)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Current Load").font(.headline)
                    HStack { Text("CPU").frame(width: 80, alignment: .leading); JuicerUsageBar(value: manager.cpuPercent, color: .blue); Text(SystemMetricsSupport.percent(manager.cpuPercent)).frame(width: 64, alignment: .trailing) }
                    HStack(spacing: 20) { Text("Load average (1 / 5 / 15 min)"); Spacer(); Text(manager.loadAverages.map { String(format: "%.2f", $0) }.joined(separator: "  /  ")).monospacedDigit().foregroundStyle(.secondary) }
                }
                .padding(16).background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recent samples").font(.headline)
                    ForEach(manager.samples.suffix(12)) { sample in
                        HStack(spacing: 10) { Text(SystemMetricsSupport.time(sample.date)).font(.caption).foregroundStyle(.secondary).frame(width: 76, alignment: .leading); Text("CPU").font(.caption); JuicerUsageBar(value: sample.cpuPercent, color: .blue); Text("MEM").font(.caption); JuicerUsageBar(value: sample.memoryPercent, color: .purple) }
                    }
                    if manager.samples.isEmpty { JuicerEmptyState(title: "Collecting metrics", detail: "The first sample will appear shortly.") }
                }
            }
            .padding(24)
        }
        .onAppear { manager.start() }.onDisappear { manager.stop() }
    }
}
