import SwiftUI

struct mainsidebarview: View {
    @State private var selectedItem: NavigationItem? = .dashboard
    @State private var isShowingGuide = false
    
    var body: some View {
        VStack(spacing: 0) {
            NavigationSplitView {
                List(selection: $selectedItem) {
                    Section("General") {
                        sidebarLink(for: .dashboard)
                    }
                    
                    Section("Monitor") {
                        sidebarLink(for: .statusMonitor)
                        sidebarLink(for: .portListener)
                    }
                    
                    Section("Applications") {
                        sidebarLink(for: .appStore)
                        sidebarLink(for: .appUninstaller)
                        sidebarLink(for: .orphanScanner)
                        sidebarLink(for: .appLipo)
                        sidebarLink(for: .brewExplorer)
                    }
                    
                    Section("Storage & Disk") {
                        sidebarLink(for: .diskExplorer)
                        sidebarLink(for: .cacheCleaner)
                        sidebarLink(for: .devCaches)
                        sidebarLink(for: .largeFiles)
                        sidebarLink(for: .hiddenFiles)
                    }
                    
                    Section("System & Advanced") {
                        sidebarLink(for: .systemOptimizer)
                        sidebarLink(for: .serviceManager)
                        sidebarLink(for: .systemTweaks)
                        sidebarLink(for: .quarantineStripper)
                        sidebarLink(for: .dnsEditor)
                        sidebarLink(for: .launchServices)
                        sidebarLink(for: .sdkSwitcher)
                        sidebarLink(for: .snapshots)
                        sidebarLink(for: .scriptConsole)
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
            
            statusbarview()
        }
        // Menu navigation event listeners
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.dashboard"))) { _ in selectedItem = .dashboard }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.uninstaller"))) { _ in selectedItem = .appUninstaller }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.orphans"))) { _ in selectedItem = .orphanScanner }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.caches"))) { _ in selectedItem = .devCaches }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.largeFiles"))) { _ in selectedItem = .largeFiles }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.hiddenFiles"))) { _ in selectedItem = .hiddenFiles }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.brewExplorer"))) { _ in selectedItem = .brewExplorer }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.serviceManager"))) { _ in selectedItem = .serviceManager }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.systemTweaks"))) { _ in selectedItem = .systemTweaks }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.diskExplorer"))) { _ in selectedItem = .diskExplorer }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.systemOptimizer"))) { _ in selectedItem = .systemOptimizer }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.statusMonitor"))) { _ in selectedItem = .statusMonitor }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.cacheCleaner"))) { _ in selectedItem = .cacheCleaner }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.appStore"))) { _ in selectedItem = .appStore }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.snapshots"))) { _ in selectedItem = .snapshots }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.scriptConsole"))) { _ in selectedItem = .scriptConsole }
        
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.uninstaller.scan"))) { notification in
            if let appURL = notification.object as? URL {
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
