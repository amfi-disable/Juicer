import SwiftUI

struct powerscheduleview: View {
    @StateObject private var manager = PowerScheduleManager()
    @State private var action = "sleep"
    @State private var date = Date().addingTimeInterval(3600)

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            JuicerFeatureHeader(title: "Timer-Based Power Schedule", subtitle: "Schedule sleep, wake, shutdown, or restart events.", icon: "calendar.badge.clock", refreshing: manager.refreshing, action: manager.refresh)
            HStack {
                Picker("Action", selection: $action) { Text("Sleep").tag("sleep"); Text("Wake").tag("wakeorpoweron"); Text("Shutdown").tag("shutdown"); Text("Restart").tag("restart") }
                DatePicker("When", selection: $date, in: Date()...)
                Button("Schedule") { manager.schedule(action: action, date: date) }.buttonStyle(.borderedProminent)
            }
            if !manager.message.isEmpty { Text(manager.message).font(.caption).foregroundStyle(.secondary) }
            JuicerFeatureList(title: "Scheduled events") {
                ForEach(manager.schedules) { item in Text(item.date).font(.system(.caption, design: .monospaced)) }
                if manager.schedules.isEmpty { Text("No scheduled power events.").foregroundStyle(.secondary) }
            }
            Spacer()
        }.padding(24).onAppear { manager.refresh() }
    }
}

struct thermalmonitorview: View {
    @StateObject private var manager = ThermalMonitorManager()
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 18) {
            JuicerFeatureHeader(title: "Thermal Throttling Monitor", subtitle: "Inspect thermal pressure and CPU throttling signals.", icon: "thermometer.medium", refreshing: manager.refreshing, action: manager.refresh)
            JuicerMetricTile(title: "Status", value: manager.reading.level, detail: manager.reading.detail, color: manager.reading.throttling ? .orange : .green)
            Text(manager.reading.throttling ? "Close demanding apps, improve airflow, and allow the Mac to cool." : "No active throttling signal was reported by macOS.").foregroundStyle(.secondary)
        }.padding(24) }.onAppear { manager.refresh() }
    }
}

struct fancontrollerview: View {
    @StateObject private var manager = FanControllerManager()
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            JuicerFeatureHeader(title: "Fan Speed Controller", subtitle: "Use manual presets only when compatible hardware is detected.", icon: "fanblades.fill", refreshing: manager.refreshing, action: manager.refresh)
            HStack { Button("Quiet · 2000 RPM") { manager.applyMinimumRPM(2000) }; Button("Balanced · 3500 RPM") { manager.applyMinimumRPM(3500) }; Button("Cooling · 5000 RPM") { manager.applyMinimumRPM(5000) } }.disabled(!manager.supported)
            if !manager.message.isEmpty { Text(manager.message).foregroundStyle(.secondary) }
            JuicerFeatureList(title: "Fan telemetry") { ForEach(manager.fans) { Text($0.text).font(.system(.caption, design: .monospaced)) }; if manager.fans.isEmpty { Text("No fan telemetry available.").foregroundStyle(.secondary) } }
            Spacer()
        }.padding(24).onAppear { manager.refresh() }
    }
}

struct memorypurgeview: View {
    @StateObject private var manager = MemoryPurgeManager()
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 18) {
            JuicerFeatureHeader(title: "RAM Cleaner / Memory Purge", subtitle: "Review memory pressure and invoke macOS's purge command on demand.", icon: "memorychip", refreshing: manager.purging, action: manager.refresh)
            HStack { JuicerMetricTile(title: "Used", value: SystemMetricsSupport.bytes(manager.reading.used), detail: manager.reading.status, color: .blue); JuicerMetricTile(title: "Free", value: SystemMetricsSupport.bytes(manager.reading.free), detail: "currently free", color: .green); JuicerMetricTile(title: "Purgeable", value: SystemMetricsSupport.bytes(manager.reading.purgeable), detail: "reclaimable estimate", color: .orange) }
            Button("Purge Inactive Memory") { manager.purge() }.buttonStyle(.borderedProminent).disabled(manager.purging)
            Text("Purging can temporarily affect performance while caches are rebuilt.").font(.caption).foregroundStyle(.secondary)
        }.padding(24) }.onAppear { manager.refresh() }
    }
}
