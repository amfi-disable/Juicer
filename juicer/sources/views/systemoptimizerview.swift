import SwiftUI

struct systemoptimizerview: View {
    @StateObject private var manager = SystemOptimizerManager()
    @State private var activeTab: Tab = .optimize
    @State private var showFirstAlert = false
    @State private var showSecondAlert = false
    @State private var filterCategory: OptimizationTask.TaskCategory? = nil

    enum Tab: String, CaseIterable {
        case optimize = "Optimizer"
        case health = "System Health"
        case log = "Run Log"
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection()
            Divider()
            tabContent()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            manager.loadHealthMetrics()
        }
        .alert("Warning: Run System Optimizations?", isPresented: $showFirstAlert) {
            Button("Proceed", role: .none) { showSecondAlert = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You are about to run \(manager.tasks.filter { $0.isSelected && $0.status == .pending }.count) optimization tasks. Some actions affect system state and may require a restart. Proceed?")
        }
        .alert("Final Confirmation", isPresented: $showSecondAlert) {
            Button("Confirm & Optimize", role: .destructive) { manager.runSelectedTasks() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Selected optimization tasks will now execute. Any failed tasks will be logged. This cannot be undone.")
        }
    }

    // MARK: - Header
    @ViewBuilder
    private func headerSection() -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("System Optimizer")
                    .font(.title2).bold()
                Text("Run targeted optimization tasks to refresh caches, flush DNS, purge memory, and tune system performance — inspired by Mole.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }

            Spacer()

            // Status badge
            if manager.isRunning {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text("Running…").font(.caption).foregroundStyle(.secondary)
                }
            } else if manager.completedCount > 0 || manager.failedCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("\(manager.completedCount) done, \(manager.failedCount) failed")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            Picker("", selection: $activeTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 280)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }

    // MARK: - Tab Router
    @ViewBuilder
    private func tabContent() -> some View {
        switch activeTab {
        case .optimize: optimizerTab()
        case .health: healthTab()
        case .log: logTab()
        }
    }

    // MARK: - Optimizer Tab
    @ViewBuilder
    private func optimizerTab() -> some View {
        VStack(spacing: 0) {
            // Category filter bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    categoryChip(label: "All", category: nil)
                    ForEach(OptimizationTask.TaskCategory.allCases, id: \.self) { cat in
                        categoryChip(label: cat.rawValue, category: cat)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.25))

            Divider()

            // Task list
            List {
                let filtered = filterCategory == nil ? manager.tasks : manager.tasks.filter { $0.category == filterCategory }
                ForEach(filtered.indices, id: \.self) { originalIdx in
                    let task = filtered[originalIdx]
                    taskRow(task: task)
                }
            }
            .listStyle(.inset)

            Divider()

            // Bottom action bar
            HStack {
                let selectedCount = manager.tasks.filter { $0.isSelected && $0.status == .pending }.count
                Text("\(selectedCount) tasks selected")
                    .font(.subheadline).foregroundStyle(.secondary)
                Spacer()

                Button("Reset All") {
                    manager.resetTasks()
                }
                .buttonStyle(.bordered)
                .disabled(manager.isRunning)

                Button(action: { showFirstAlert = true }) {
                    HStack {
                        Image(systemName: "bolt.fill")
                        Text("Run Optimizations")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(manager.isRunning || manager.tasks.filter({ $0.isSelected && $0.status == .pending }).isEmpty)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
        }
    }

    @ViewBuilder
    private func categoryChip(label: String, category: OptimizationTask.TaskCategory?) -> some View {
        let isActive = filterCategory == category
        Button(action: { filterCategory = category }) {
            Text(label)
                .font(.caption).bold()
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(isActive ? Color.accentColor : Color.secondary.opacity(0.1))
                .foregroundStyle(isActive ? .white : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func taskRow(task: OptimizationTask) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Toggle("", isOn: Binding(
                get: { task.isSelected },
                set: { val in
                    if let idx = manager.tasks.firstIndex(where: { $0.id == task.id }) {
                        manager.tasks[idx].isSelected = val
                    }
                }
            ))
            .toggleStyle(.checkbox)
            .disabled(task.status == .running || manager.isRunning)
            .padding(.top, 3)

            // Status icon
            statusIcon(for: task.status)
                .padding(.top, 3)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.name)
                        .font(.headline)
                    categoryBadge(task.category)
                }
                Text(task.description)
                    .font(.subheadline).foregroundStyle(.secondary)
                    .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                if !task.resultMessage.isEmpty && task.status != .pending {
                    Text(task.resultMessage)
                        .font(.caption2).foregroundStyle(.tertiary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 6)
        .opacity(task.status == .failed ? 0.6 : 1.0)
    }

    @ViewBuilder
    private func statusIcon(for status: OptimizationTask.TaskStatus) -> some View {
        switch status {
        case .pending:
            Image(systemName: "circle").foregroundStyle(.secondary)
        case .running:
            ProgressView().controlSize(.small)
        case .success:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
        case .skipped:
            Image(systemName: "minus.circle").foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func categoryBadge(_ category: OptimizationTask.TaskCategory) -> some View {
        let color = categoryColor(category)
        Text(category.rawValue)
            .font(.caption2).bold()
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .cornerRadius(4)
    }

    private func categoryColor(_ category: OptimizationTask.TaskCategory) -> Color {
        switch category {
        case .system: return .blue
        case .developer: return .orange
        case .network: return .cyan
        case .memory: return .purple
        case .storage: return .green
        }
    }

    // MARK: - Health Tab
    @ViewBuilder
    private func healthTab() -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Live System Health")
                    .font(.headline).padding()
                Spacer()
                if manager.isLoadingMetrics {
                    ProgressView().controlSize(.small).padding()
                } else {
                    Button(action: { manager.loadHealthMetrics() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered).padding()
                }
            }
            Divider()

            if manager.isLoadingMetrics {
                VStack {
                    ProgressView("Loading system metrics…")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(manager.healthMetrics) { metric in
                            metricCard(metric: metric)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    @ViewBuilder
    private func metricCard(metric: SystemHealthMetric) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: metric.icon)
                    .foregroundStyle(.blue)
                Text(metric.category)
                    .font(.caption2).bold()
                    .foregroundStyle(.secondary)
            }
            Text(metric.name)
                .font(.subheadline).bold()
            Text(metric.value)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Log Tab
    @ViewBuilder
    private func logTab() -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Optimization Run Log")
                    .font(.headline).padding()
                Spacer()
                if !manager.runLog.isEmpty {
                    Button("Clear") { manager.runLog = [] }
                        .buttonStyle(.bordered).padding()
                }
            }
            Divider()

            if manager.runLog.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 36)).foregroundStyle(.secondary)
                    Text("No logs yet")
                        .font(.headline).foregroundStyle(.secondary)
                    Text("Run optimizations to see the log output here.")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(manager.runLog.enumerated()), id: \.offset) { idx, line in
                                Text(line)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(logLineColor(line))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .id(idx)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: manager.runLog.count) { _ in
                        if let last = manager.runLog.indices.last {
                            withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                        }
                    }
                }
            }
        }
    }

    private func logLineColor(_ line: String) -> Color {
        if line.hasPrefix("✅") { return .green }
        if line.hasPrefix("❌") { return .red }
        if line.hasPrefix("▶") { return .blue }
        if line.hasPrefix("🏁") { return .orange }
        return .primary
    }
}
