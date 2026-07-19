import SwiftUI

enum UnifiedStoreItem: String, CaseIterable, Identifiable {
    case allCasks = "All Casks"
    case installedCasks = "Installed Casks"
    case updatesCasks = "Cask Updates"
    
    case allFormulae = "All Formulae"
    case installedFormulae = "Installed Formulae"
    case updatesFormulae = "Formula Updates"
    
    case services = "Background Services"
    case taps = "Taps Repositories"
    case brewfile = "Brewfile Sync"
    case diagnostics = "Diagnostics & Maintenance"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .allCasks: return "square.grid.3x3.fill"
        case .installedCasks: return "app.badge.checkmark.fill"
        case .updatesCasks: return "arrow.up.circle.fill"
        case .allFormulae: return "terminal.fill"
        case .installedFormulae: return "checkmark.seal.fill"
        case .updatesFormulae: return "arrow.triangle.2.circlepath.circle.fill"
        case .services: return "gearshape.2.fill"
        case .taps: return "square.3.layers.3d.down.forward"
        case .brewfile: return "doc.text.magnifyingglass"
        case .diagnostics: return "waveform.path.ecg.rectangle.fill"
        }
    }
}

struct mainsidebarview: View {
    @State private var currentWorkspace: JuicerWorkspace = .hub
    @State private var selectedItem: NavigationItem? = nil
    @State private var selectedStoreItem: UnifiedStoreItem = .allCasks
    @State private var isShowingGuide = false
    
    var body: some View {
        VStack(spacing: 0) {
            if currentWorkspace == .hub {
                hubLaunchpadView()
            } else if currentWorkspace == .store {
                NavigationSplitView {
                    List(selection: $selectedStoreItem) {
                        // Return to App Hub button
                        Button(action: {
                            withAnimation {
                                currentWorkspace = .hub
                                selectedItem = nil
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.left.circle.fill")
                                    .font(.title3)
                                Text("Back to App Hub")
                                    .font(.headline)
                            }
                            .foregroundColor(.accentColor)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        
                        Divider().padding(.vertical, 4)
                        
                        Section("Cask Store (Apps)") {
                            sidebarStoreLink(for: .allCasks)
                            sidebarStoreLink(for: .installedCasks)
                            sidebarStoreLink(for: .updatesCasks)
                        }
                        
                        Section("Brew Store (CLI)") {
                            sidebarStoreLink(for: .allFormulae)
                            sidebarStoreLink(for: .installedFormulae)
                            sidebarStoreLink(for: .updatesFormulae)
                        }
                        
                        Section("Homebrew Utilities") {
                            sidebarStoreLink(for: .services)
                            sidebarStoreLink(for: .taps)
                            sidebarStoreLink(for: .brewfile)
                            sidebarStoreLink(for: .diagnostics)
                        }
                    }
                    .listStyle(.sidebar)
                    .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
                } detail: {
                    switch selectedStoreItem {
                    case .allCasks:
                        storeview(isCask: true, filterType: .all)
                    case .installedCasks:
                        storeview(isCask: true, filterType: .installed)
                    case .updatesCasks:
                        storeview(isCask: true, filterType: .updates)
                    case .allFormulae:
                        storeview(isCask: false, filterType: .all)
                    case .installedFormulae:
                        storeview(isCask: false, filterType: .installed)
                    case .updatesFormulae:
                        storeview(isCask: false, filterType: .updates)
                    case .services:
                        brewservicesview()
                    case .taps:
                        brewtapsview()
                    case .brewfile:
                        brewfilesyncview()
                    case .diagnostics:
                        brewmanagerview(selectedTab: 3)
                    }
                }
            } else {
                NavigationSplitView {
                    List(selection: $selectedItem) {
                        // Return to App Hub button
                        Button(action: {
                            withAnimation {
                                currentWorkspace = .hub
                                selectedItem = nil
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.left.circle.fill")
                                    .font(.title3)
                                Text("Back to App Hub")
                                    .font(.headline)
                            }
                            .foregroundColor(.accentColor)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        
                        Divider().padding(.vertical, 4)
                        
                        // Dynamically filtered workspace sections
                        let items = NavigationItem.allCases.filter { $0.workspace == currentWorkspace }
                        Section(currentWorkspace.title) {
                            ForEach(items) { item in
                                sidebarLink(for: item)
                            }
                        }
                    }
                    .listStyle(.sidebar)
                    .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
                } detail: {
                    if let item = selectedItem {
                        switch item {
                        case .dashboard:        dashboardview()
                        case .appUninstaller:   appuninstallerview()
                        case .orphanScanner:    orphanscannerview()
                        case .serviceManager:   launchdmanagerview()
                        case .devCaches:        cacheprunerview()
                        case .systemTweaks:     systemtweakerview()
                        case .quarantineStripper: quarantinestripperview()
                        case .dnsEditor:        dnseditorview()
                        case .launchServices:   launchservicesview()
                        case .hiddenFiles:      hiddenfileview()
                        case .appLipo:          applipoview()
                        case .largeFiles:       largefilesview()
                        case .brewExplorer:     brewmanagerview()
                        case .sdkSwitcher:      sdkmanagerview()
                        case .portListener:     portlistenerview()
                        case .diskExplorer:     diskexplorerview()
                        case .systemOptimizer:  systemoptimizerview()
                        case .statusMonitor:    statusmonitorview()
                        case .cacheCleaner:     cachecleanerview()
                        case .appStore:         storeview()
                        case .snapshots:        snapshotsview()
                        case .scriptConsole:    scriptconsoleview()
                        case .utilitiesView:    utilitiesview()
                        case .diskVisualizer:   diskvisualizerview()
                        case .undoHistory:      deletionhistoryview()
                        case .appUpdates:       appupdaterview()
                        case .tccViewer:        tccviewerview()
                        case .cpuMemoryMonitor: cpumemorymonitorview()
                        case .gpuMonitor:       gpumonitorview()
                        case .diskIOMonitor:    diskiomonitorview()
                        case .networkTraffic:   networktrafficmonitorview()
                        case .batteryHealth:    batteryhealthview()
                        case .startupItems:     startupitemview()
                        case .loginItemDelays:  loginitemdelayview()
                        case .processKiller:    processkillerview()
                        case .systemLogs:       systemlogview()
                        case .kextManager:      kextmanagerview()
                        case .powerSchedule:   powerscheduleview()
                        case .thermalMonitor:  thermalmonitorview()
                        case .fanController:   fancontrollerview()
                        case .memoryPurge:     memorypurgeview()
                        case .swapManager:     swapmanagerview()
                        case .vpnProfiles:     vpnprofileview()
                        case .networkLocations: networklocationview()
                        case .bluetoothDevices: bluetoothdeviceview()
                        case .airDropQuickSend: airdropquicksendview()
                        case .duplicateFiles:  duplicatefileview()
                        case .emptyFolders:   emptyfolderview()
                        case .downloadOrganizer: downloadorganizerview()
                        case .archiveUtility: archiveutilityview()
                        case .diskImages:     diskimageview()
                        case .permissionRepair: permissionrepairview()
                        case .extendedAttributes: extendedattributeview()
                        case .fileTypeConverter: filetypeconverterview()
                        case .metadataEditor: metadataeditorview()
                        case .symbolicLinks: symboliclinkview()
                        case .diskVerification: diskverificationview()
                        case .storageSnapshots: storagesnapshotview()
                        case .fileVault: filevaultview()
                        case .firewall: firewallview()
                        case .privacyScanner: privacyscannerview()
                        case .passwordAudit: passwordauditview()
                        }
                    } else {
                        VStack {
                            Image(systemName: "square.dashed")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 8)
                            Text("No Tool Selected")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            statusbarview()
        }
        // Menu navigation event listeners (switching workspace automatically)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.dashboard"))) { _ in
            currentWorkspace = .system
            selectedItem = .dashboard
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.uninstaller"))) { _ in
            currentWorkspace = .configs
            selectedItem = .appUninstaller
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.orphans"))) { _ in
            currentWorkspace = .configs
            selectedItem = .orphanScanner
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.caches"))) { _ in
            currentWorkspace = .disk
            selectedItem = .devCaches
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.largeFiles"))) { _ in
            currentWorkspace = .disk
            selectedItem = .largeFiles
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.hiddenFiles"))) { _ in
            currentWorkspace = .disk
            selectedItem = .hiddenFiles
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.brewExplorer"))) { _ in
            currentWorkspace = .store
            selectedItem = .brewExplorer
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.serviceManager"))) { _ in
            currentWorkspace = .configs
            selectedItem = .serviceManager
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.systemTweaks"))) { _ in
            currentWorkspace = .configs
            selectedItem = .systemTweaks
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.diskExplorer"))) { _ in
            currentWorkspace = .disk
            selectedItem = .diskExplorer
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.systemOptimizer"))) { _ in
            currentWorkspace = .configs
            selectedItem = .systemOptimizer
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.statusMonitor"))) { _ in
            currentWorkspace = .system
            selectedItem = .statusMonitor
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.cacheCleaner"))) { _ in
            currentWorkspace = .disk
            selectedItem = .cacheCleaner
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.appStore"))) { _ in
            currentWorkspace = .store
            selectedItem = .appStore
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.snapshots"))) { _ in
            currentWorkspace = .system
            selectedItem = .snapshots
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.scriptConsole"))) { _ in
            currentWorkspace = .system
            selectedItem = .scriptConsole
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.utilities"))) { _ in
            currentWorkspace = .utilities
            selectedItem = .utilitiesView
        }
        
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.uninstaller.scan"))) { notification in
            if let appURL = notification.object as? URL {
                currentWorkspace = .configs
                selectedItem = .appUninstaller
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    NotificationCenter.default.post(name: NSNotification.Name("juicer.action.triggerScan"), object: appURL)
                }
            }
        }
        
        .onAppear {
            TrashObserver.shared.startObserving()
        }
        
        // Help & Guide triggers
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.action.showGuide"))) { _ in
            isShowingGuide = true
        }
        .sheet(isPresented: $isShowingGuide) {
            userGuideSheet()
        }
    }
    
    // MARK: - Startup Hub Launchpad View
    @ViewBuilder
    private func hubLaunchpadView() -> some View {
        VStack(spacing: 30) {
            Spacer()
            
            // App Hub Header
            VStack(spacing: 10) {
                Text("Juicer App Hub")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Select a specialized bundled workspace companion below to begin.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 20)
            
            // Startup App Grid (No Icons)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)], spacing: 20) {
                hubAppCard(workspace: .store, defaultItem: .appStore)
                hubAppCard(workspace: .system, defaultItem: .dashboard)
                hubAppCard(workspace: .disk, defaultItem: .diskExplorer)
                hubAppCard(workspace: .configs, defaultItem: .appUninstaller)
                hubAppCard(workspace: .utilities, defaultItem: .utilitiesView)
            }
            .frame(maxWidth: 880)
            
            Spacer()
        }
        .padding(40)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    @ViewBuilder
    private func hubAppCard(workspace: JuicerWorkspace, defaultItem: NavigationItem) -> some View {
        Button(action: {
            withAnimation {
                currentWorkspace = workspace
                selectedItem = defaultItem
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                Text(workspace.title)
                    .font(.title3).bold()
                    .foregroundColor(.primary)
                Text(workspace.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                HStack {
                    Spacer()
                    Text("Launch Workspace →")
                        .font(.caption2).bold()
                        .foregroundColor(.accentColor)
                }
            }
            .padding(24)
            .frame(height: 150)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.secondary.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func sidebarLink(for item: NavigationItem) -> some View {
        NavigationLink(value: item) {
            HStack(spacing: 10) {
                Image(systemName: item.iconName)
                    .font(.body)
                    .frame(width: 18, alignment: .center)
                Text(item.title)
                    .font(.body)
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func sidebarStoreLink(for item: UnifiedStoreItem) -> some View {
        Button(action: {
            selectedStoreItem = item
        }) {
            HStack(spacing: 10) {
                Image(systemName: item.iconName)
                    .font(.body)
                    .frame(width: 18, alignment: .center)
                    .foregroundColor(selectedStoreItem == item ? .accentColor : .primary)
                Text(item.rawValue)
                    .font(.body)
                    .foregroundColor(selectedStoreItem == item ? .accentColor : .primary)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(selectedStoreItem == item ? Color.accentColor.opacity(0.12) : Color.clear)
        .cornerRadius(6)
    }
    
    // MARK: - Help User Guide
    @ViewBuilder
    private func userGuideSheet() -> some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .font(.title2).foregroundColor(.accentColor)
                Text("Juicer Help Manual & User Guide")
                    .font(.title3).bold()
                Spacer()
                Button("Done") { isShowingGuide = false }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("Welcome to Juicer")
                            .font(.title2).bold().foregroundColor(.accentColor)
                        Text("Juicer is an open-source macOS developer utility. It combines disk analysis, live system monitoring, developer cache management, app uninstalling, and system optimization — all in one native app.")
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    Group {
                        Text("Core Modules")
                            .font(.headline)
                        
                        guideItem(title: "Live Status Monitor", icon: "waveform.path.ecg", color: .green,
                            desc: "Real-time CPU gauges, memory pressure, network speed, health scoring, and a full process list with force-quit support. Refresh rate is fully configurable (1s / 2s / 5s / 10s / 30s / Manual).")
                        
                        guideItem(title: "Cache Cleaner & Space Insights", icon: "sparkle.magnifyingglass", color: .orange,
                            desc: "27 categorised cleanable space items (iOS Backups, Xcode Simulators, Docker, Spotify, JetBrains, and more) plus a project scanner that finds node_modules, .build, target/, venv/ and other dependency directories.")
                        
                        guideItem(title: "Disk Explorer", icon: "internaldrive.fill", color: .blue,
                            desc: "Visualize disk usage with proportional bar maps. Browse all mounted volumes including external drives, drill into any folder, and reveal items in Finder.")
                        
                        guideItem(title: "System Optimizer", icon: "bolt.fill", color: .yellow,
                            desc: "15 targeted optimisation tasks: flush DNS, purge memory, rebuild LaunchServices DB, clear QuickLook caches, update Homebrew and more.")
                        
                        guideItem(title: "Developer Caches", icon: "hammer.fill", color: .indigo,
                            desc: "50+ cache targets covering Xcode, Node, Python, Ruby, Rust, Go, Java, Docker, VS Code, JetBrains, Terraform, and more.")
                        
                        guideItem(title: "Software Center", icon: "square.grid.3x3.fill", color: .purple,
                            desc: "Explore Homebrew's vast catalog of graphical applications (Casks) and command line utilities (Formulae). Installs and uninstalls items directly with a real-time console log.")
                        
                        guideItem(title: "App Uninstaller & Orphan Finder", icon: "trash.fill", color: .red,
                            desc: "Detect and remove leftover files from previously uninstalled apps.")
                        
                        guideItem(title: "SDK & Runtime Switcher", icon: "square.stack.3d.up.fill", color: .purple,
                            desc: "Switch between Node.js, Python, Ruby, and Rust versions using nvm, pyenv, rbenv, and rustup.")
                        
                        guideItem(title: "Port Listener", icon: "network.badge.shield.half.filled", color: .teal,
                            desc: "Inspect open network ports and kill hanging server processes.")
                        
                        guideItem(title: "Homebrew Explorer", icon: "shippingbox.fill", color: .cyan,
                            desc: "Manage Homebrew formulae, casks, run brew doctor, and cleanup downloads.")
                    }
                    
                    Divider()
                    
                    Group {
                        Text("Keyboard Shortcuts").font(.headline)
                        VStack(alignment: .leading, spacing: 8) {
                            shortcutRow(keys: "Cmd + 1", desc: "Dashboard")
                            shortcutRow(keys: "Cmd + 2", desc: "App Uninstaller")
                            shortcutRow(keys: "Cmd + 3", desc: "Orphan Finder")
                            shortcutRow(keys: "Cmd + 4", desc: "Developer Caches")
                            shortcutRow(keys: "Cmd + 5", desc: "Large & Old Files")
                            shortcutRow(keys: "Cmd + 6", desc: "Hidden File Explorer")
                            shortcutRow(keys: "Cmd + 7", desc: "Homebrew Explorer")
                            shortcutRow(keys: "Cmd + 8", desc: "Service Manager")
                            shortcutRow(keys: "Cmd + 9", desc: "System Tweaks")
                            shortcutRow(keys: "Cmd + Shift + S", desc: "Live Status Monitor")
                            shortcutRow(keys: "Cmd + Shift + M", desc: "Cache Cleaner")
                            shortcutRow(keys: "Cmd + Shift + D", desc: "Disk Explorer")
                            shortcutRow(keys: "Cmd + Shift + O", desc: "System Optimizer")
                            shortcutRow(keys: "Cmd + Shift + A", desc: "Software Center")
                            shortcutRow(keys: "Cmd + ,", desc: "Preferences / Settings")
                            shortcutRow(keys: "Cmd + ?", desc: "This Help Guide")
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
        .frame(width: 620, height: 560)
    }
    
    @ViewBuilder
    private func guideItem(title: String, icon: String, color: Color, desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.15)).frame(width: 32, height: 32)
                Image(systemName: icon).foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).bold()
                Text(desc).font(.subheadline).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func shortcutRow(keys: String, desc: String) -> some View {
        HStack {
            Text(keys).font(.system(.body, design: .monospaced)).bold()
                .foregroundColor(.accentColor).frame(width: 190, alignment: .leading)
            Text(desc).foregroundColor(.secondary)
            Spacer()
        }
    }
}
