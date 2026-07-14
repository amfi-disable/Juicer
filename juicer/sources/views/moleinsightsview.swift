import SwiftUI

struct moleinsightsview: View {
    @StateObject private var manager = MoleInsightsManager()
    @State private var activeTab: InsightsTab = .insights
    @State private var filterCategory: InsightItem.InsightCategory? = nil
    @State private var projectRootInput: String = ""
    @State private var showFirstAlert = false
    @State private var showSecondAlert = false
    @State private var showProjectFirstAlert = false
    @State private var showProjectSecondAlert = false
    @State private var resultMessage: String = ""
    @State private var showResult = false

    enum InsightsTab: String, CaseIterable {
        case insights = "Space Insights"
        case projects = "Project Cleaner"
        case log = "Clean Log"
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection()
            Divider()

            switch activeTab {
            case .insights: insightsTab()
            case .projects: projectCleanerTab()
            case .log: logTab()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear { manager.scanSizes() }
        .alert("Move to Trash?", isPresented: $showFirstAlert) {
            Button("Proceed") { showSecondAlert = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will move \(manager.insights.filter { $0.isSelected && $0.exists }.count) items to Trash. They can be recovered from Trash if needed.")
        }
        .alert("Confirm Clean", isPresented: $showSecondAlert) {
            Button("Confirm & Trash", role: .destructive) {
                manager.trashSelected { count, freed in
                    resultMessage = "Trashed \(count) items, freed \(MoleInsightsManager.formatBytes(freed))."
                    showResult = true
                    manager.scanSizes()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Items will be permanently moved to the Trash. Continue?")
        }
        .alert("Clean Project Deps?", isPresented: $showProjectFirstAlert) {
            Button("Proceed") { showProjectSecondAlert = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will move \(manager.projectEntries.filter { $0.isSelected }.count) dependency directories to the Trash.")
        }
        .alert("Confirm Project Clean", isPresented: $showProjectSecondAlert) {
            Button("Confirm & Clean", role: .destructive) {
                manager.trashProjectDeps { count, freed in
                    resultMessage = "Cleaned \(count) directories, freed \(MoleInsightsManager.formatBytes(freed))."
                    showResult = true
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Selected node_modules/.build/target/etc. directories will be trashed. They will be regenerated on next build.")
        }
        .alert("Done", isPresented: $showResult) {
            Button("OK") {}
        } message: {
            Text(resultMessage)
        }
    }

    // MARK: - Header
    @ViewBuilder
    private func headerSection() -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Mole Insights & Project Cleaner")
                    .font(.title2).bold()
                Text("27 cleanable space categories and project dependency detection — inspired by Mole's \u{2018}mo clean\u{2019} and \u{2018}mo analyze\u{2019}.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()

            if manager.totalCleanableBytes > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "externaldrive.badge.minus").foregroundStyle(.orange)
                    Text(MoleInsightsManager.formatBytes(manager.totalCleanableBytes))
                        .font(.subheadline).bold().foregroundStyle(.orange)
                    Text("cleanable").font(.caption2).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            Picker("", selection: $activeTab) {
                ForEach(InsightsTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 320)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }

    // MARK: ─────────────────────────────────────────
    // MARK: INSIGHTS TAB
    // MARK: ─────────────────────────────────────────
    @ViewBuilder
    private func insightsTab() -> some View {
        VStack(spacing: 0) {
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(label: "All", category: nil)
                    ForEach(InsightItem.InsightCategory.allCases, id: \.self) { cat in
                        filterChip(label: cat.rawValue, category: cat, icon: cat.icon)
                    }
                }
                .padding(.horizontal).padding(.vertical, 10)
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.25))

            Divider()

            if manager.isScanning {
                VStack(spacing: 12) {
                    ProgressView("Measuring space usage…").progressViewStyle(.circular)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let filtered = filterCategory == nil ? manager.insights :
                    manager.insights.filter { $0.category == filterCategory }

                List {
                    ForEach(filtered) { item in
                        insightRow(item: item)
                    }
                }
                .listStyle(.inset)
            }

            Divider()
            insightsActionBar()
        }
    }

    @ViewBuilder
    private func insightRow(item: InsightItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Toggle("", isOn: Binding(
                get: { item.isSelected },
                set: { val in
                    if let idx = manager.insights.firstIndex(where: { $0.id == item.id }) {
                        manager.insights[idx].isSelected = val
                    }
                }
            ))
            .toggleStyle(.checkbox)
            .disabled(!item.exists || manager.isCleaning)
            .padding(.top, 2)

            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(categoryColor(item.category).opacity(0.12))
                    .frame(width: 30, height: 30)
                Image(systemName: item.category.icon)
                    .font(.caption).foregroundStyle(categoryColor(item.category))
            }
            .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(item.name).font(.headline)
                    if !item.exists {
                        Text("Not Found")
                            .font(.caption2).padding(.horizontal, 5).padding(.vertical, 1)
                            .background(Color.secondary.opacity(0.15))
                            .foregroundStyle(.secondary).cornerRadius(3)
                    }
                }
                Text(item.description)
                    .font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                Text(item.path)
                    .font(.caption2).foregroundStyle(.tertiary).lineLimit(1).truncationMode(.middle)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                if item.sizeBytes >= 0 && item.exists {
                    Text(MoleInsightsManager.formatBytes(item.sizeBytes))
                        .font(.subheadline).bold()
                        .foregroundStyle(item.sizeBytes > 500_000_000 ? .red : item.sizeBytes > 100_000_000 ? .orange : .primary)
                } else if item.exists {
                    ProgressView().controlSize(.mini)
                }

                if item.exists {
                    Button(action: {
                        NSWorkspace.shared.selectFile(item.path, inFileViewerRootedAtPath: "")
                    }) {
                        Image(systemName: "arrow.up.forward.square")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Reveal in Finder")
                }
            }
        }
        .padding(.vertical, 5)
        .opacity(item.exists ? 1 : 0.4)
    }

    @ViewBuilder
    private func insightsActionBar() -> some View {
        HStack {
            let selectedCount = manager.insights.filter { $0.isSelected && $0.exists }.count
            let selectedSize = manager.insights.filter { $0.isSelected && $0.exists }.reduce(0) { $0 + $1.sizeBytes }

            Text("\(selectedCount) selected (\(MoleInsightsManager.formatBytes(selectedSize)))")
                .font(.subheadline).foregroundStyle(.secondary)
            Spacer()

            Button("Select All") {
                for i in manager.insights.indices where manager.insights[i].exists {
                    manager.insights[i].isSelected = true
                }
            }
            .buttonStyle(.bordered)

            Button("Rescan") { manager.scanSizes() }
                .buttonStyle(.bordered)
                .disabled(manager.isScanning)

            Button(action: { showFirstAlert = true }) {
                HStack {
                    if manager.isCleaning {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "trash.fill")
                    }
                    Text("Move to Trash")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(selectedCount == 0 || manager.isCleaning || manager.isScanning)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }

    // MARK: ─────────────────────────────────────────
    // MARK: PROJECT CLEANER TAB
    // MARK: ─────────────────────────────────────────
    @ViewBuilder
    private func projectCleanerTab() -> some View {
        VStack(spacing: 0) {
            // Root selector
            HStack(spacing: 10) {
                Image(systemName: "folder.fill").foregroundStyle(.blue)
                TextField("Project root directory (leave empty for home)…", text: $projectRootInput)
                    .textFieldStyle(.roundedBorder)

                Button("Scan") {
                    manager.scanProjectDeps(root: projectRootInput)
                }
                .buttonStyle(.borderedProminent)
                .disabled(manager.isScanning)

                Button("Browse…") {
                    let panel = NSOpenPanel()
                    panel.canChooseDirectories = true
                    panel.canChooseFiles = false
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK {
                        projectRootInput = panel.url?.path ?? ""
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.25))

            Divider()

            if manager.isScanning {
                VStack(spacing: 12) {
                    ProgressView("Scanning for dependency directories…").progressViewStyle(.circular)
                    if !manager.projectScanRoot.isEmpty {
                        Text(manager.projectScanRoot)
                            .font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if manager.projectEntries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles").font(.system(size: 40)).foregroundStyle(.secondary)
                    Text("No cleanable directories found")
                        .font(.headline).foregroundStyle(.secondary)
                    Text("Scan a project root to find node_modules, .build, target/, venv/, and more.")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center).padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                projectList()
            }

            Divider()
            projectActionBar()
        }
    }

    @ViewBuilder
    private func projectList() -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Type").frame(width: 130, alignment: .leading)
                Text("Path").frame(maxWidth: .infinity, alignment: .leading)
                Text("Size").frame(width: 90, alignment: .trailing)
            }
            .font(.caption2).bold().foregroundStyle(.secondary)
            .padding(.horizontal).padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.2))

            Divider()

            List {
                ForEach(manager.projectEntries) { entry in
                    HStack {
                        Toggle("", isOn: Binding(
                            get: { entry.isSelected },
                            set: { val in
                                if let idx = manager.projectEntries.firstIndex(where: { $0.id == entry.id }) {
                                    manager.projectEntries[idx].isSelected = val
                                }
                            }
                        ))
                        .toggleStyle(.checkbox)

                        Image(systemName: dirIcon(entry.dirType))
                            .foregroundStyle(dirColor(entry.dirType))
                            .frame(width: 18)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.name).font(.subheadline).bold()
                            Text(entry.path)
                                .font(.caption2).foregroundStyle(.tertiary)
                                .lineLimit(1).truncationMode(.middle)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(MoleInsightsManager.formatBytes(entry.sizeBytes))
                            .font(.subheadline).bold()
                            .foregroundStyle(entry.sizeBytes > 500_000_000 ? .red : .primary)
                            .frame(width: 80, alignment: .trailing)

                        Button(action: {
                            NSWorkspace.shared.selectFile(entry.path, inFileViewerRootedAtPath: "")
                        }) {
                            Image(systemName: "arrow.up.forward.square").foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 3)
                }
            }
            .listStyle(.inset)
        }
    }

    @ViewBuilder
    private func projectActionBar() -> some View {
        HStack {
            let selectedCount = manager.projectEntries.filter { $0.isSelected }.count
            let selectedSize = manager.projectEntries.filter { $0.isSelected }.reduce(0) { $0 + $1.sizeBytes }

            Text("\(manager.projectEntries.count) dirs found · \(selectedCount) selected (\(MoleInsightsManager.formatBytes(selectedSize)))")
                .font(.subheadline).foregroundStyle(.secondary)
            Spacer()

            Button("Select All") {
                for i in manager.projectEntries.indices { manager.projectEntries[i].isSelected = true }
            }.buttonStyle(.bordered)
            Button("Select None") {
                for i in manager.projectEntries.indices { manager.projectEntries[i].isSelected = false }
            }.buttonStyle(.bordered)

            Button(action: { showProjectFirstAlert = true }) {
                HStack {
                    if manager.isCleaning { ProgressView().controlSize(.small) }
                    else { Image(systemName: "trash.fill") }
                    Text("Clean Selected")
                }
            }
            .buttonStyle(.borderedProminent).tint(.red)
            .disabled(selectedCount == 0 || manager.isCleaning || manager.isScanning)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }

    // MARK: ─────────────────────────────────────────
    // MARK: LOG TAB
    // MARK: ─────────────────────────────────────────
    @ViewBuilder
    private func logTab() -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Clean Operation Log").font(.headline).padding()
                Spacer()
                if !manager.log.isEmpty {
                    Button("Clear") { manager.log = [] }.buttonStyle(.bordered).padding()
                }
            }
            Divider()
            if manager.log.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text").font(.system(size: 36)).foregroundStyle(.secondary)
                    Text("No operations yet").font(.headline).foregroundStyle(.secondary)
                    Text("Clean some items to see the log here.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(manager.log.enumerated()), id: \.offset) { idx, line in
                                Text(line)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(line.hasPrefix("❌") ? .red : line.hasPrefix("🗑") ? .green : .primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .id(idx)
                            }
                        }.padding()
                    }
                    .onChange(of: manager.log.count) { _ in
                        if let last = manager.log.indices.last { proxy.scrollTo(last, anchor: .bottom) }
                    }
                }
            }
        }
    }

    // MARK: - Helpers
    @ViewBuilder
    private func filterChip(label: String, category: InsightItem.InsightCategory?, icon: String? = nil) -> some View {
        let active = filterCategory == category
        Button(action: { filterCategory = category }) {
            HStack(spacing: 4) {
                if let icon { Image(systemName: icon).font(.caption2) }
                Text(label).font(.caption).bold()
            }
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(active ? Color.accentColor : Color.secondary.opacity(0.1))
            .foregroundStyle(active ? .white : .primary)
            .cornerRadius(20)
        }.buttonStyle(.plain)
    }

    private func categoryColor(_ cat: InsightItem.InsightCategory) -> Color {
        switch cat {
        case .system: return .blue
        case .media: return .pink
        case .developer: return .orange
        case .deps: return .teal
        case .ide: return .purple
        }
    }

    private func dirIcon(_ type: String) -> String {
        if type == "node_modules" { return "shippingbox.fill" }
        if type.hasPrefix(".") && type.contains("cache") { return "folder.badge.minus" }
        if ["target", "build", "dist", "out"].contains(type) { return "hammer.fill" }
        if ["venv", ".venv", "virtualenv"].contains(type) { return "curlybraces" }
        if type == "Pods" { return "cube.fill" }
        return "folder.badge.minus"
    }

    private func dirColor(_ type: String) -> Color {
        if type == "node_modules" { return .green }
        if ["target", "build", "dist", ".build"].contains(type) { return .orange }
        if ["venv", ".venv", "__pycache__"].contains(type) { return .blue }
        if type == "Pods" || type == "DerivedData" { return .purple }
        return .secondary
    }
}
