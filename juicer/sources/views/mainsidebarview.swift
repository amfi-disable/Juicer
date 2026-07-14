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
                    
                    Section("Applications") {
                        sidebarLink(for: .appUninstaller)
                        sidebarLink(for: .orphanScanner)
                        sidebarLink(for: .appLipo)
                        sidebarLink(for: .brewExplorer)
                    }
                    
                    Section("Storage & Disk") {
                        sidebarLink(for: .diskExplorer)
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
                        sidebarLink(for: .portListener)
                    }
                }
                .listStyle(.sidebar)
                .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
            } detail: {
                if let item = selectedItem {
                    switch item {
                    case .dashboard:
                        dashboardview()
                    case .appUninstaller:
                        appuninstallerview()
                    case .orphanScanner:
                        orphanscannerview()
                    case .serviceManager:
                        launchdmanagerview()
                    case .devCaches:
                        cacheprunerview()
                    case .systemTweaks:
                        systemtweakerview()
                    case .quarantineStripper:
                        quarantinestripperview()
                    case .dnsEditor:
                        dnseditorview()
                    case .launchServices:
                        launchservicesview()
                    case .hiddenFiles:
                        hiddenfileview()
                    case .appLipo:
                        applipoview()
                    case .largeFiles:
                        largefilesview()
                    case .brewExplorer:
                        brewmanagerview()
                    case .sdkSwitcher:
                        sdkmanagerview()
                    case .portListener:
                        portlistenerview()
                    case .diskExplorer:
                        diskexplorerview()
                    case .systemOptimizer:
                        systemoptimizerview()
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
    
    // MARK: - Interactive Help User Guide Modal
    @ViewBuilder
    private func userGuideSheet() -> some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("Juicer Help Manual & User Guide")
                    .font(.title3)
                    .bold()
                Spacer()
                Button("Done") {
                    isShowingGuide = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("Welcome to Juicer")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.accentColor)
                        Text("Juicer is an open-source utility designed specifically for macOS developers to keep their systems clean, optimize cache files, inspect listening network ports, and manage environments.")
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    Group {
                        Text("Core Modules Guide")
                            .font(.headline)
                        
                        guideItem(
                            title: "App Uninstaller & Orphan Finder",
                            icon: "trash.fill",
                            color: .red,
                            desc: "Drag and drop any application or click 'Select App Manually' to scan for leftovers. Orphan Finder sweeps away remnants from previously deleted applications."
                        )
                        
                        guideItem(
                            title: "Disk Explorer",
                            icon: "internaldrive.fill",
                            color: .blue,
                            desc: "Visualize disk usage across your volumes with a Mole-inspired bar map. Drill down into folders, identify space hogs, and reveal items in Finder."
                        )
                        
                        guideItem(
                            title: "System Optimizer",
                            icon: "bolt.fill",
                            color: .orange,
                            desc: "Run 15+ targeted optimization tasks: flush DNS cache, purge memory, rebuild Launch Services, clear QuickLook caches, update Homebrew, and more. Inspired by Mole's 'mo optimize' command."
                        )
                        
                        guideItem(
                            title: "Developer Caches",
                            icon: "hammer.fill",
                            color: .indigo,
                            desc: "Quickly reclaim gigabytes of disk space by purging DerivedData, Node packages caches, Cargo/Rust target folders, and dangling Docker images."
                        )
                        
                        guideItem(
                            title: "SDK & Runtime Switcher",
                            icon: "square.stack.3d.up.fill",
                            color: .purple,
                            desc: "Seamlessly swap between active versions of Node.js (nvm/fnm), Python (pyenv), Ruby (rbenv/rvm), and Rust (rustup). Changes require double confirmation dialog checks for safety."
                        )
                        
                        guideItem(
                            title: "Port Listener & Process Killer",
                            icon: "network.badge.shield.half.filled",
                            color: .orange,
                            desc: "Inspect open network ports using List View or the Process Relationship Graph. Terminate hanging servers with single-click options. Configure force-killing options using Settings."
                        )
                        
                        guideItem(
                            title: "Homebrew Explorer",
                            icon: "shippingbox.fill",
                            color: .cyan,
                            desc: "Manage formula and casks lists, run system diagnostics using 'brew doctor', or clear downloads archives using 'brew cleanup'."
                        )
                    }
                    
                    Divider()
                    
                    Group {
                        Text("Keyboard Shortcuts Reference")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            shortcutRow(keys: "Cmd + 1", desc: "Go to Dashboard")
                            shortcutRow(keys: "Cmd + 2", desc: "Go to App Uninstaller")
                            shortcutRow(keys: "Cmd + 3", desc: "Go to Orphan Finder")
                            shortcutRow(keys: "Cmd + 4", desc: "Go to Developer Caches")
                            shortcutRow(keys: "Cmd + 5", desc: "Go to Large & Old Files")
                            shortcutRow(keys: "Cmd + 6", desc: "Go to Hidden File Explorer")
                            shortcutRow(keys: "Cmd + 7", desc: "Go to Homebrew Explorer")
                            shortcutRow(keys: "Cmd + 8", desc: "Go to Service Manager")
                            shortcutRow(keys: "Cmd + 9", desc: "Go to System Tweaks")
                            shortcutRow(keys: "Cmd + Shift + D", desc: "Go to Disk Explorer")
                            shortcutRow(keys: "Cmd + Shift + O", desc: "Go to System Optimizer")
                            shortcutRow(keys: "Cmd + Shift + B", desc: "Add Custom Bookmark Link")
                            shortcutRow(keys: "Cmd + ,", desc: "Open Preferences / Settings")
                            shortcutRow(keys: "Cmd + ?", desc: "Open this Help Guide Manual")
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
        .frame(width: 600, height: 540)
    }
    
    @ViewBuilder
    private func guideItem(title: String, icon: String, color: Color, desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).bold()
                Text(desc)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func shortcutRow(keys: String, desc: String) -> some View {
        HStack {
            Text(keys)
                .font(.system(.body, design: .monospaced))
                .bold()
                .foregroundColor(.accentColor)
                .frame(width: 180, alignment: .leading)
            Text(desc)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}
