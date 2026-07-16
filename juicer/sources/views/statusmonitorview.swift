import SwiftUI

struct statusmonitorview: View {
    @StateObject private var manager = StatusMonitorManager()
    @State private var activeTab: MonitorTab = .overview
    @State private var killTargetPID: Int? = nil
    @State private var showKillConfirm = false
    @State private var killMessage: String = ""
    @State private var showKillResult = false
    @State private var selectedRogueProcess: ProcessMonitorEntry? = nil

    enum MonitorTab: String, CaseIterable {
        case overview = "Overview"
        case processes = "Processes"
        case health = "Health"
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar()
            Divider()

            if manager.isLoading {
                loadingPlaceholder()
            } else {
                switch activeTab {
                case .overview:   overviewTab()
                case .processes:  processesTab()
                case .health:     healthTab()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear { manager.start() }
        .onDisappear { manager.stop() }
        .alert("Kill Process?", isPresented: $showKillConfirm) {
            Button("Kill \(killTargetPID.map(String.init) ?? "")", role: .destructive) {
                if let pid = killTargetPID {
                    manager.kill(pid: pid) { success in
                        killMessage = success ? "Process \(pid) terminated." : "Failed to kill process \(pid). You may need elevated privileges."
                        showKillResult = true
                        manager.refresh()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will forcefully terminate PID \(killTargetPID.map(String.init) ?? ""). This action cannot be undone.")
        }
        .alert("Result", isPresented: $showKillResult) {
            Button("OK") {}
        } message: {
            Text(killMessage)
        }
    }

    // MARK: - Header
    @ViewBuilder
    private func headerBar() -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text("Live Status Monitor")
                        .font(.title2).bold()
                    // Pulsing dot when refreshing
                    if manager.isRefreshing {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 7, height: 7)
                            .opacity(0.8)
                    }
                }
                Text("Real-time CPU, memory, network and process monitoring.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()

            // Hardware badge
            if !manager.hardware.modelName.isEmpty {
                HStack(spacing: 5) {
                    Image(systemName: "laptopcomputer")
                        .foregroundStyle(.secondary)
                    Text(manager.hardware.modelName)
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }

            // Refresh rate control
            HStack(spacing: 4) {
                Image(systemName: "clock").foregroundStyle(.secondary).font(.caption)
                Picker("", selection: $manager.refreshInterval) {
                    ForEach(StatusMonitorManager.RefreshInterval.allCases) { interval in
                        Text(interval.rawValue).tag(interval)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 90)
                .help("Auto-refresh interval")
            }
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(7)

            Picker("", selection: $activeTab) {
                ForEach(MonitorTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 280)

            Button(action: { manager.refresh() }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .disabled(manager.isRefreshing)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }

    // MARK: - Loading
    @ViewBuilder
    private func loadingPlaceholder() -> some View {
        VStack(spacing: 16) {
            ProgressView().progressViewStyle(.circular).scaleEffect(1.2)
            Text("Collecting system metrics…")
                .font(.headline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: ─────────────────────────────────────────
    // MARK: OVERVIEW TAB
    // MARK: ─────────────────────────────────────────
    @ViewBuilder
    private func overviewTab() -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Row 1: CPU + Memory
                HStack(spacing: 16) {
                    cpuCard()
                    memoryCard()
                }

                // Row 2: GPU + Bluetooth
                HStack(spacing: 16) {
                    gpuCard()
                    bluetoothCard()
                }

                // Row 3: Network + Health Score
                HStack(spacing: 16) {
                    networkCard()
                    healthScoreCard()
                }

                // Row 4: Top Processes
                topProcessesCard()
            }
            .padding()
        }
    }

    // MARK: CPU Card
    @ViewBuilder
    private func cpuCard() -> some View {
        metricCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "cpu").foregroundStyle(.blue)
                    Text("CPU").font(.headline)
                    Spacer()
                    Text(String(format: "%.1f%%", manager.cpu.usagePercent))
                        .font(.title3).bold()
                        .foregroundStyle(cpuColor(manager.cpu.usagePercent))
                }

                // Circular gauge
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: manager.cpu.usagePercent / 100)
                        .stroke(
                            cpuColor(manager.cpu.usagePercent),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.6), value: manager.cpu.usagePercent)
                    VStack(spacing: 2) {
                        Text(String(format: "%.0f%%", manager.cpu.usagePercent))
                            .font(.title2).bold()
                        Text("usage").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .frame(width: 90, height: 90)
                .frame(maxWidth: .infinity)

                Divider()
                HStack {
                    statPill("Cores", "\(manager.cpu.coreCount)")
                    Spacer()
                    statPill("1m", String(format: "%.2f", manager.cpu.loadAvg1))
                    statPill("5m", String(format: "%.2f", manager.cpu.loadAvg5))
                    statPill("15m", String(format: "%.2f", manager.cpu.loadAvg15))
                }
                .font(.caption)
            }
        }
    }

    // MARK: Memory Card
    @ViewBuilder
    private func memoryCard() -> some View {
        metricCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "memorychip").foregroundStyle(.purple)
                    Text("Memory").font(.headline)
                    Spacer()
                    pressureBadge(manager.memory.pressure)
                }

                // Horizontal usage bar
                VStack(alignment: .leading, spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.secondary.opacity(0.15))
                            RoundedRectangle(cornerRadius: 6)
                                .fill(memColor(manager.memory.usedPercent))
                                .frame(width: geo.size.width * (manager.memory.usedPercent / 100))
                                .animation(.easeInOut(duration: 0.6), value: manager.memory.usedPercent)
                        }
                    }
                    .frame(height: 14)
                    HStack {
                        Text(StatusMonitorManager.formatBytes(manager.memory.usedBytes))
                            .font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text(StatusMonitorManager.formatBytes(manager.memory.totalBytes))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }

                Divider()
                HStack {
                    statPill("Used", String(format: "%.1f%%", manager.memory.usedPercent))
                    Spacer()
                    if manager.memory.swapTotalBytes > 0 {
                        statPill("Swap", StatusMonitorManager.formatBytes(manager.memory.swapUsedBytes))
                    }
                    statPill("Free", StatusMonitorManager.formatBytes(manager.memory.freeBytes))
                }
                .font(.caption)
            }
        }
    }

    // MARK: GPU Card
    @ViewBuilder
    private func gpuCard() -> some View {
        metricCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "square.fill.on.square.fill").foregroundStyle(.orange)
                    Text("GPU").font(.headline)
                    Spacer()
                    Text(String(format: "%.1f%%", manager.gpu.usagePercent))
                        .font(.title3).bold()
                        .foregroundStyle(.orange)
                }

                VStack(alignment: .leading, spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.secondary.opacity(0.15))
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.orange)
                                .frame(width: geo.size.width * (manager.gpu.usagePercent / 100))
                                .animation(.easeInOut(duration: 0.6), value: manager.gpu.usagePercent)
                        }
                    }
                    .frame(height: 12)
                    
                    HStack {
                        Text("VRAM: " + StatusMonitorManager.formatBytes(UInt64(manager.gpu.vramUsedBytes)))
                            .font(.caption2).foregroundStyle(.secondary)
                        Spacer()
                        Text(StatusMonitorManager.formatBytes(UInt64(manager.gpu.vramTotalBytes)))
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }

                Divider()
                Text(manager.gpu.modelName)
                    .font(.caption).foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    // MARK: Bluetooth Card
    @ViewBuilder
    private func bluetoothCard() -> some View {
        metricCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "wave.3.left.fill").foregroundStyle(.blue)
                    Text("Bluetooth").font(.headline)
                    Spacer()
                    Text(manager.bluetooth.isEnabled ? "ON" : "OFF")
                        .font(.subheadline).bold()
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(manager.bluetooth.isEnabled ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                        .foregroundStyle(manager.bluetooth.isEnabled ? Color.green : Color.red)
                        .cornerRadius(4)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Connected Devices:")
                        .font(.caption).bold().foregroundStyle(.secondary)
                    
                    if manager.bluetooth.connectedDevices.isEmpty {
                        Text("No devices connected")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(manager.bluetooth.connectedDevices, id: \.self) { device in
                            HStack {
                                Image(systemName: "link").font(.caption2).foregroundStyle(.secondary)
                                Text(device).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
            }
        }
    }

    // MARK: Network Card
    @ViewBuilder
    private func networkCard() -> some View {
        metricCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "network").foregroundStyle(.cyan)
                    Text("Network").font(.headline)
                    Spacer()
                    if !manager.network.interfaceName.isEmpty {
                        Text(manager.network.interfaceName)
                            .font(.caption2)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.cyan.opacity(0.12))
                            .cornerRadius(4)
                    }
                }

                HStack(spacing: 16) {
                    VStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.title2).foregroundStyle(.green)
                        Text(StatusMonitorManager.formatSpeed(manager.network.rxBytesPerSec))
                            .font(.headline).bold()
                        Text("Download").font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    Divider().frame(height: 50)

                    VStack(spacing: 6) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2).foregroundStyle(.orange)
                        Text(StatusMonitorManager.formatSpeed(manager.network.txBytesPerSec))
                            .font(.headline).bold()
                        Text("Upload").font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 4)

                Divider()
                HStack {
                    statPill("Total ↓", StatusMonitorManager.formatBytes(manager.network.totalRxBytes))
                    Spacer()
                    statPill("Total ↑", StatusMonitorManager.formatBytes(manager.network.totalTxBytes))
                }
                .font(.caption)
            }
        }
    }

    // MARK: Health Score Card
    @ViewBuilder
    private func healthScoreCard() -> some View {
        metricCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "heart.fill").foregroundStyle(.pink)
                    Text("Health Score").font(.headline)
                    Spacer()
                }

                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: Double(manager.health.score) / 100)
                        .stroke(healthColor(manager.health.score),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(), value: manager.health.score)
                    VStack(spacing: 2) {
                        Text("\(manager.health.score)")
                            .font(.title).bold()
                        Text(manager.health.grade)
                            .font(.caption2).foregroundStyle(healthColor(manager.health.score))
                    }
                }
                .frame(width: 90, height: 90)
                .frame(maxWidth: .infinity)

                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(manager.health.tips.prefix(2), id: \.self) { tip in
                        HStack(alignment: .top, spacing: 5) {
                            Image(systemName: "info.circle")
                                .font(.caption2).foregroundStyle(.secondary)
                            Text(tip).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: Top Processes Card
    @ViewBuilder
    private func topProcessesCard() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "chart.bar.fill").foregroundStyle(.orange)
                Text("Top Processes by CPU")
                    .font(.headline)
                Spacer()
                Button("See All") { activeTab = .processes }
                    .buttonStyle(.plain).foregroundStyle(Color.accentColor)
                    .font(.caption)
            }
            .padding()

            Divider()

            VStack(spacing: 0) {
                ForEach(Array(manager.topProcesses.enumerated()), id: \.element.id) { idx, proc in
                    HStack(spacing: 12) {
                        Text("#\(idx + 1)")
                            .font(.caption2).foregroundStyle(.tertiary)
                            .frame(width: 24)

                        Text(proc.name)
                            .font(.subheadline)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.orange.opacity(0.1))
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.orange.opacity(0.6))
                                    .frame(width: geo.size.width * min(proc.cpuPercent / 100, 1))
                            }
                        }
                        .frame(width: 80, height: 8)

                        Text(String(format: "%.1f%%", proc.cpuPercent))
                            .font(.caption).bold()
                            .frame(width: 50, alignment: .trailing)

                        Text(StatusMonitorManager.formatBytes(proc.memBytes))
                            .font(.caption2).foregroundStyle(.secondary)
                            .frame(width: 70, alignment: .trailing)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    if idx < manager.topProcesses.count - 1 {
                        Divider().padding(.leading)
                    }
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.1), lineWidth: 1))
    }

    // MARK: ─────────────────────────────────────────
    // MARK: PROCESSES TAB
    // MARK: ─────────────────────────────────────────
    @ViewBuilder
    private func processesTab() -> some View {
        VStack(spacing: 0) {
            // Search + Sort bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search by name, command, or PID…", text: $manager.processSearchQuery)
                    .textFieldStyle(.plain)
                if !manager.processSearchQuery.isEmpty {
                    Button(action: { manager.processSearchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }.buttonStyle(.plain)
                }
                Divider().frame(height: 20)
                Text("Sort:").font(.caption).foregroundStyle(.secondary)
                Picker("", selection: $manager.processSortKey) {
                    ForEach(StatusMonitorManager.ProcessSortKey.allCases, id: \.self) { key in
                        Text(key.rawValue).tag(key)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 100)
            }
            .padding(.horizontal).padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.3))

            Divider()

            // Column headers
            HStack {
                Text("PID").frame(width: 60, alignment: .leading)
                Text("Name").frame(maxWidth: .infinity, alignment: .leading)
                Text("CPU %").frame(width: 60, alignment: .trailing)
                Text("Memory").frame(width: 80, alignment: .trailing)
                Text("Actions").frame(width: 60, alignment: .center)
            }
            .font(.caption2).bold().foregroundStyle(.secondary)
            .padding(.horizontal).padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.2))

            Divider()

            List(manager.filteredProcesses) { proc in
                let isRogue = proc.cpuPercent > 80.0 || proc.memBytes > 2_000_000_000
                HStack {
                    Text("\(proc.pid)")
                        .font(.system(.caption, design: .monospaced))
                        .frame(width: 60, alignment: .leading)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        if isRogue {
                            Button(action: { selectedRogueProcess = proc }) {
                                Image(systemName: "exclamationmark.octagon.fill")
                                    .foregroundColor(.orange)
                                    .help("Rogue resource pressure warning")
                            }
                            .buttonStyle(.plain)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(proc.name)
                                .font(.subheadline)
                                .lineLimit(1)
                            Text(proc.command)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(String(format: "%.1f%%", proc.cpuPercent))
                        .font(.caption).bold()
                        .foregroundStyle(proc.cpuPercent > 50 ? .red : proc.cpuPercent > 20 ? .orange : .primary)
                        .frame(width: 60, alignment: .trailing)

                    Text(StatusMonitorManager.formatBytes(proc.memBytes))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 80, alignment: .trailing)

                    Button(action: {
                        killTargetPID = proc.pid
                        showKillConfirm = true
                    }) {
                        Image(systemName: "xmark.circle")
                            .foregroundStyle(.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .help("Force quit PID \(proc.pid)")
                    .frame(width: 60)
                }
                .padding(.vertical, 3)
                .popover(item: $selectedRogueProcess) { rogueProc in
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange).font(.title3)
                            Text("Rogue Resource Alert").font(.headline).bold()
                        }
                        Divider()
                        Text("Process '\(rogueProc.name)' (PID \(rogueProc.pid)) is consuming abnormally high system resources:")
                            .font(.subheadline)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• CPU Consumption: \(String(format: "%.1f%%", rogueProc.cpuPercent))")
                            Text("• Memory Footprint: \(StatusMonitorManager.formatBytes(rogueProc.memBytes))")
                        }
                        .font(.caption).bold()
                        
                        Text("This resource pressure might drain battery, lock core execution threads, or cause macOS UI stuttering. Terminating the process is recommended.")
                            .font(.caption).foregroundColor(.secondary)
                        
                        Divider()
                        HStack {
                            Button("Force Quit Process") {
                                manager.kill(pid: rogueProc.pid) { success in
                                    killMessage = success ? "Process \(rogueProc.pid) terminated." : "Failed to terminate process \(rogueProc.pid)."
                                    showKillResult = true
                                    selectedRogueProcess = nil
                                    manager.refresh()
                                }
                            }
                            .buttonStyle(.borderedProminent).tint(.red)
                            
                            Spacer()
                            
                            Button("Ignore") {
                                selectedRogueProcess = nil
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                    .frame(width: 380)
                }
            }
            .listStyle(.inset)

            // Status bar
            HStack {
                Text("\(manager.filteredProcesses.count) processes")
                    .font(.caption2).foregroundStyle(.secondary)
                Spacer()
                if manager.isRefreshing {
                    ProgressView().controlSize(.mini)
                }
            }
            .padding(.horizontal).padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.2))
        }
    }

    // MARK: ─────────────────────────────────────────
    // MARK: HEALTH TAB
    // MARK: ─────────────────────────────────────────
    @ViewBuilder
    private func healthTab() -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Big health score
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(healthColor(manager.health.score).opacity(0.15), lineWidth: 20)
                            .frame(width: 140, height: 140)
                        Circle()
                            .trim(from: 0, to: Double(manager.health.score) / 100)
                            .stroke(healthColor(manager.health.score),
                                    style: StrokeStyle(lineWidth: 20, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.8), value: manager.health.score)
                            .frame(width: 140, height: 140)
                        VStack(spacing: 4) {
                            Text("\(manager.health.score)")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(healthColor(manager.health.score))
                            Text("/ 100")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }

                    Text(manager.health.grade)
                        .font(.title2).bold()
                        .padding(.horizontal, 20).padding(.vertical, 6)
                        .background(healthColor(manager.health.score).opacity(0.15))
                        .cornerRadius(20)
                        .foregroundStyle(healthColor(manager.health.score))
                }
                .padding(.top, 8)
                .frame(maxWidth: .infinity)

                // Breakdown grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    healthBreakdownCard(
                        title: "CPU",
                        icon: "cpu",
                        value: String(format: "%.1f%%", manager.cpu.usagePercent),
                        subtitle: "Load: \(String(format: "%.2f", manager.cpu.loadAvg1)) / \(String(format: "%.2f", manager.cpu.loadAvg5)) / \(String(format: "%.2f", manager.cpu.loadAvg15))",
                        color: cpuColor(manager.cpu.usagePercent)
                    )
                    healthBreakdownCard(
                        title: "Memory",
                        icon: "memorychip",
                        value: String(format: "%.1f%%", manager.memory.usedPercent),
                        subtitle: "Pressure: \(manager.memory.pressure.capitalized)",
                        color: memColor(manager.memory.usedPercent)
                    )
                    healthBreakdownCard(
                        title: "Model",
                        icon: "laptopcomputer",
                        value: manager.hardware.chipName.isEmpty ? "Mac" : manager.hardware.chipName,
                        subtitle: manager.hardware.osVersion,
                        color: .blue
                    )
                    healthBreakdownCard(
                        title: "RAM",
                        icon: "square.stack.3d.up",
                        value: manager.hardware.totalRAMFormatted,
                        subtitle: "Available: \(StatusMonitorManager.formatBytes(manager.memory.freeBytes))",
                        color: .purple
                    )
                }

                // Tips
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "lightbulb.fill").foregroundStyle(.yellow)
                        Text("Recommendations")
                            .font(.headline)
                    }
                    Divider()
                    ForEach(manager.health.tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundStyle(Color.accentColor).font(.body)
                            Text(tip)
                                .font(.subheadline).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                .cornerRadius(12)
            }
            .padding()
        }
    }

    @ViewBuilder
    private func healthBreakdownCard(title: String, icon: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).foregroundStyle(color)
                Text(title).font(.subheadline).bold()
            }
            Text(value).font(.title3).bold().foregroundStyle(color)
            Text(subtitle).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.2), lineWidth: 1))
    }

    // MARK: ─────────────────────────────────────────
    // MARK: Reusable Components
    // MARK: ─────────────────────────────────────────

    @ViewBuilder
    private func metricCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.1), lineWidth: 1))
    }

    @ViewBuilder
    private func statPill(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).bold().foregroundStyle(.primary)
            Text(label).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func pressureBadge(_ pressure: String) -> some View {
        let (label, color): (String, Color) = {
            switch pressure {
            case "critical": return ("Critical", .red)
            case "warn": return ("Elevated", .orange)
            default: return ("Normal", .green)
            }
        }()
        Text(label)
            .font(.caption2).bold()
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .cornerRadius(4)
    }

    // MARK: - Color helpers
    private func cpuColor(_ pct: Double) -> Color {
        pct > 85 ? .red : pct > 50 ? .orange : .blue
    }
    private func memColor(_ pct: Double) -> Color {
        pct > 88 ? .red : pct > 70 ? .orange : .purple
    }
    private func healthColor(_ score: Int) -> Color {
        score >= 85 ? .green : score >= 65 ? .blue : score >= 45 ? .orange : .red
    }
}
