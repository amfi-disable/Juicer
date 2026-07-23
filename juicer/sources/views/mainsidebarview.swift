import SwiftUI
import AppKit

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
    @State private var isShowingCommandPalette = false
    @State private var sidebarSearch = ""
    @AppStorage("juicer.settings.showStatusBar") private var showStatusBar = true
    @AppStorage("juicer.settings.restoreMainWindow") private var restoreMainWindow = true
    @AppStorage("juicer.settings.sidebarWidth") private var sidebarWidth = 240
    @AppStorage("juicer.settings.appearance") private var appearance = "system"
    @AppStorage("juicer.settings.accentColor") private var accentColor = "orange"
    @AppStorage("juicer.settings.compactNavigation") private var compactNavigation = false
    @AppStorage("juicer.settings.hideRecentNavigation") private var hideRecentNavigation = false
    @AppStorage("juicer.settings.hubDensity") private var hubDensity = "comfortable"
    @StateObject private var navigationPreferences = navigationpreferences.shared
    @State private var hasAppeared = false
    @State private var sidebarScope = "all"
    @State private var isEcosystemExpanded = true
    @State private var showTerminal = false
    
    // Home Screen Canvas Drag Panning State
    @State private var hubOffset: CGSize = .zero
    @State private var lastHubOffset: CGSize = .zero
    @State private var isShowingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            if currentWorkspace == .hub {
                hubLaunchpadView()
            } else if currentWorkspace == .store {
                NavigationSplitView {
                    List(selection: $selectedStoreItem) {
                        // Return to App Hub button
                        JuicerBackToHubButton {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                currentWorkspace = .hub
                                selectedItem = nil
                            }
                        }
                        
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
                    .navigationSplitViewColumnWidth(min: 200, ideal: CGFloat(sidebarWidth), max: 340)
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
                        JuicerBackToHubButton {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                currentWorkspace = .hub
                                selectedItem = nil
                            }
                        }
                        
                        Divider().padding(.vertical, 4)

                        Picker("Tool scope", selection: $sidebarScope) {
                            Label("All", systemImage: "square.grid.2x2").tag("all")
                            Label("Favorites", systemImage: "star").tag("favorites")
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 4)
                        
                        // Dynamically filtered workspace items
                        let items = NavigationItem.allCases.filter { item in
                            let matchesScope: Bool = (sidebarScope == "favorites") ? navigationPreferences.isFavorite(item) : true
                            return item.workspace == currentWorkspace && matchesScope && (sidebarSearch.isEmpty || item.title.localizedCaseInsensitiveContains(sidebarSearch))
                        }
                        
                        // Workspace Header & Controls
                        Section(header: HStack(spacing: 6) {
                            Image(systemName: currentWorkspace.iconName)
                                .font(.caption.bold())
                                .foregroundColor(currentWorkspace.themeColor)
                            Text(currentWorkspace.title)
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Spacer()
                            if !compactNavigation {
                                Text("\(items.count)")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(currentWorkspace.themeColor.opacity(0.14), in: Capsule())
                                    .foregroundColor(currentWorkspace.themeColor)
                            }
                        }) {
                            if !navigationPreferences.favorites.filter({ $0.workspace == currentWorkspace }).isEmpty && sidebarScope == "all" {
                                Section("Favorites ⭐") {
                                    ForEach(navigationPreferences.favorites.filter { $0.workspace == currentWorkspace }) { item in
                                        sidebarLink(for: item)
                                    }
                                }
                            }
                            
                            // Direct Subcategory Listing (1-Click Instant Navigation)
                            let categories = Array(Set(items.map { $0.subcategory })).sorted()
                            ForEach(categories, id: \.self) { category in
                                let categoryItems = items.filter { $0.subcategory == category }
                                    .sorted { item1, item2 in
                                        if item1 == .brewGhost { return true }
                                        if item2 == .brewGhost { return false }
                                        return item1.title < item2.title
                                    }
                                if !categoryItems.isEmpty {
                                    Section(category) {
                                        ForEach(categoryItems) { item in
                                            sidebarLink(for: item)
                                        }
                                    }
                                }
                            }
                        }
                        

                        // Footer Settings & Minimize Controls
                        Section("Preferences") {
                            Button(action: { isShowingSettings = true }) {
                                HStack(spacing: compactNavigation ? 0 : 10) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.body)
                                        .frame(width: 18, alignment: .center)
                                        .foregroundColor(.accentColor)
                                    if !compactNavigation {
                                        Text("App Settings")
                                            .font(.body)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.vertical, 4)
                            .help("Open Juicer Preferences & Settings")
                            
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    compactNavigation.toggle()
                                }
                            }) {
                                HStack(spacing: compactNavigation ? 0 : 10) {
                                    Image(systemName: compactNavigation ? "sidebar.right" : "sidebar.left")
                                        .font(.body)
                                        .frame(width: 18, alignment: .center)
                                        .foregroundColor(.secondary)
                                    if !compactNavigation {
                                        Text("Minimize Sidebar")
                                            .font(.body)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.vertical, 4)
                            .help(compactNavigation ? "Expand Sidebar Labels" : "Minimize Sidebar to Icons Only")
                        }
                    }
                    .listStyle(.sidebar)
                    .searchable(text: $sidebarSearch, placement: .sidebar, prompt: compactNavigation ? "Search" : "Search workspace tools")
                    .navigationSplitViewColumnWidth(min: compactNavigation ? 56 : 220, ideal: compactNavigation ? 64 : CGFloat(sidebarWidth), max: 360)
                } detail: {
                    if let item = selectedItem {
                        switch item {
                        case .featureCatalog:   additionalfeaturecatalogview()
                        case .actionHistory:   actionhistoryview()
                        case .permissionCenter: permissioncenterview()
                        case .scriptPlugins:    scriptpluginsview()
                        case .dashboard:        dashboardview()
                        case .workflowCenter:  workflowcenterview()
                        case .appUninstaller:   appuninstallerview()
                        case .orphanScanner:    orphanscannerview()
                        case .brewGhost:        brewghostview()
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
                        case .creatorRepos:     creatorecosystemview()
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
                        case .networkTraffic:   networkbandwidthmanagerview()
                        case .envProfiles:      envprofilemanagerview()
                        case .appLanguageStripper: applanguagestripperview()
                        case .ocrScreenGrabber: ocrscreengraberview()
                        case .logStream:        logstreamview()
                        case .nlToCommand:      nltocommandview()
                        case .imageConverter:   imageconverterview()
                        case .juicerGit:        gitdashboardview()
                        case .gitExtras:        gitextrasview()
                        case .dockerDashboard, .dockerPurge, .dockerLogs, .dockerCompose: dockerstudioview()
                        case .aiWorkbench, .aiPromptVault, .aiChat, .aiKeyManager: aistudioview()
                        case .dbDaemonMonitor, .sqliteInspector, .redisViewer, .dbBackupTool: databasestudioview()
                        case .apiWorkbench, .apiBenchmark, .apiAuthManager, .apiHistory: apistudioview()
                        case .docConverter, .imageConverterStudio, .codeSchemaConverter, .archiveConverter: converterstudioview()
                        case .pathSecurityAuditor: PathSecurityAuditorView()
                        case .duplicateSanitizer: DuplicateSanitizerView()
                        case .zeroDayTCCAudit: ZeroDayTCCAuditView()
                        case .kextOrphanDetector: KernelExtensionDetectorView()
                        case .dylibOrphanDetector: DylibIntegrityDetectorView()
                        case .dockerBuildCachePurge: DockerBuildCachePurgeView()
                        case .localLLMBenchmark: LocalLLMBenchmarkView()
                        case .apiLoadTester: APILoadTesterView()
                        case .sqliteSchemaInspector: SQLiteSchemaInspectorView()
                        case .memoryPressureOptimizer: MemoryPressureOptimizerView()
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
                        case .secureDelete: securedeleteview()
                        case .quarantinedFiles: quarantinedfilesview()
                        case .sandboxInspector: sandboxinspectorview()
                        case .networkExposure: networkexposureview()
                        case .usbDeviceGuard: usbdeviceguardview()
                        case .screenRecording: screenrecordingdetectorview()
                        case .clipboardAccess: clipboardaccessview()
                        case .locationServices: locationservicesview()
                        case .microphoneCamera: microphonecameraindicatorview()
                        case .antiKeylogger: antikeyloggerscannerview()
                        case .secureNotes: securenotesvaultview()
                        case .clipboardManager: clipboardmanagerview()
                        case .snippetExpander: snippetexpanderview()
                        case .menuBarCustomizer: menubarcustomizerview()
                        case .desktopIcons: desktopiconstoggleview()
                        case .hotCorners: hotcornersview()
                        case .keyboardShortcuts: keyboardshortcutview()
                        case .textCaseConverter: textcaseconverterview()
                        case .characterCounter: charactercounterview()
                        case .qrCode: qrcodeview()
                        case .colorPicker: colorpickerview()
                        case .screenRuler: screenrulerview()
                        case .screenLoupe: screenloupeview()
                        case .batterySaver: batterysaverview()
                        case .printerQueue: printerqueueview()
                        case .pdfToolbox: pdftoolboxview()
                        case .markdownPreviewer: markdownpreviewerview()
                        case .codeSnippets: codesnippetsview()
                        case .localWebServer: localwebserverview()
                        case .portScanner: portscannerview()
                        case .lanDiscovery: landiscoveryview()
                        case .wifiSurvey: wifisurveyview()
                        case .networkProfileSwitcher: networkprofileswitcherview()
                        case .vpnAutoConnect: vpnautoconnectview()
                        case .publicIP: publicipview()
                        case .speedTest: speedtestview()
                        case .dnsDiagnostics: dnsdiagnosticsview()
                        case .hostsFile: hostsfileview()
                        case .blocklistUpdater: blocklistupdaterview()
                        case .appLocker: applockerview()
                        case .fileVaultAutoLock: filevaultautolockview()
                        case .japaneseKana: japanesekanahelperview()
                        case .emojiPicker: emojipickerview()
                        case .unicodeInspector: unicodeinspectorview()
                        case .screenshotAnnotation: screenshotannotationview()
                        case .windowSnapping: windowsnappingview()
                        case .displayProfiles: displayprofileview()
                        case .nightShift: nightshiftschedulerview()
                        case .keyboardBacklight: keyboardbacklightview()
                        case .trackpadGestures: trackpadgestureview()
                        case .shortcutRunner: shortcutrunnerview()
                        case .systemInfoExporter: systeminfoexporterview()
                        case .softwareInventory: softwareinventoryview()
                        case .autoUpdateChecker: autoupdatecheckerview()
                        case .logRotator: logrotatorview()
                        case .systemServices: systemservicesview()
                        case .diskSpacePredictor: diskspacepredictorview()
                        case .backupTrigger: backuptriggerview()
                        case .networkLimiter: networklimiterview()
                        case .diskImageMounter: diskimagemounterview()
                        case .soundVolumeMixer: soundvolumemixerview()
                        }
                    } else {
                        ContentUnavailableView("No Tool Selected", systemImage: "square.dashed", description: Text("Choose a tool from the sidebar to get started."))
                    }
                }
            }
            
            if showTerminal {
                bottomterminalview()
                Divider()
            }
            if showStatusBar {
                statusbarview()
            }
        }
        .preferredColorScheme(preferredColorScheme)
        .tint(selectedAccentColor)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.toggleTerminal"))) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                showTerminal.toggle()
            }
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.brewGhost"))) { _ in
            currentWorkspace = .configs
            selectedItem = .brewGhost
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.nav.permissionCenter"))) { _ in
            currentWorkspace = .utilities
            selectedItem = .permissionCenter
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.action.commandPalette"))) { _ in
            isShowingCommandPalette = true
        }
        .onChange(of: selectedItem) { _, item in
            if let item {
                navigationPreferences.record(item)
                currentWorkspace = item.workspace
            }
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
            guard !hasAppeared else { return }
            hasAppeared = true
            TrashObserver.shared.startObserving()
            if restoreMainWindow {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.windows.first(where: { $0.canBecomeKey && $0.title != "" })?.makeKeyAndOrderFront(nil)
            }
        }
        
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.action.refresh"))) { _ in
            AppLogger.shared.log("Cmd + R Refresh triggered.")
            NotificationCenter.default.post(name: NSNotification.Name("juicer.tool.refreshActive"), object: nil)
        }
        
        // Help & Guide triggers
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.action.showGuide"))) { _ in
            isShowingGuide = true
        }
        .sheet(isPresented: $isShowingGuide) {
            userGuideSheet()
        }
        .sheet(isPresented: $isShowingCommandPalette) {
            commandpaletteview { item in
                currentWorkspace = item.workspace
                selectedItem = item
            }
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch appearance {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    private var selectedAccentColor: Color {
        switch accentColor {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "pink": return .pink
        default: return .orange
        }
    }
    
    // MARK: - Startup Hub Launchpad View (Full-Window Centered Grid & Panning Canvas)
    @ViewBuilder
    private func hubLaunchpadView() -> some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 24)
                        
                        VStack(spacing: 32) {
                            // App Hub Header
                            VStack(spacing: 12) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 8, height: 8)
                                    Text("15 WORKSPACES READY")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(Color.green.opacity(0.12), in: Capsule())

                                Text("Juicer App Hub")
                                    .font(.system(size: min(geo.size.width * 0.04, 44), weight: .black, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.orange, .red, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                Text("Select a specialized workspace companion below to launch.")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            
                            // Startup App Grid (Expands & Fills Full Available Window)
                            let columnsCount = geo.size.width >= 1000 ? 3 : (geo.size.width >= 640 ? 2 : 1)
                            let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 20), count: columnsCount)
                            
                            LazyVGrid(columns: gridColumns, spacing: 20) {
                                hubAppCard(workspace: .store, defaultItem: .appStore)
                                hubAppCard(workspace: .system, defaultItem: .dashboard)
                                hubAppCard(workspace: .network, defaultItem: .speedTest)
                                hubAppCard(workspace: .security, defaultItem: .tccViewer)
                                hubAppCard(workspace: .disk, defaultItem: .diskExplorer)
                                hubAppCard(workspace: .developer, defaultItem: .sdkSwitcher)
                                hubAppCard(workspace: .git, defaultItem: .juicerGit)
                                hubAppCard(workspace: .containers, defaultItem: .dockerDashboard)
                                hubAppCard(workspace: .ai, defaultItem: .aiWorkbench)
                                hubAppCard(workspace: .database, defaultItem: .dbDaemonMonitor)
                                hubAppCard(workspace: .api, defaultItem: .apiWorkbench)
                                hubAppCard(workspace: .converter, defaultItem: .docConverter)
                                hubAppCard(workspace: .configs, defaultItem: .appUninstaller)
                                hubAppCard(workspace: .utilities, defaultItem: .utilitiesView)
                                hubAppCard(workspace: .creator, defaultItem: .creatorRepos)
                            }
                            .frame(maxWidth: min(geo.size.width - 64, 1280))
                        }
                        .padding(.horizontal, 32)
                        
                        Spacer(minLength: 24)
                    }
                    .frame(minWidth: geo.size.width, minHeight: geo.size.height, alignment: .center)
                    .offset(hubOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                hubOffset = CGSize(
                                    width: lastHubOffset.width + value.translation.width,
                                    height: lastHubOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastHubOffset = hubOffset
                            }
                    )
                }
                
                // Top-Right Reset Canvas Overlay (if canvas was dragged)
                if hubOffset != .zero {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            hubOffset = .zero
                            lastHubOffset = .zero
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset Position")
                        }
                        .font(.caption.weight(.medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.secondary)
                    .padding(20)
                    .transition(.opacity)
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    @ViewBuilder
    private func hubAppCard(workspace: JuicerWorkspace, defaultItem: NavigationItem) -> some View {
        let toolCount = NavigationItem.allCases.filter { $0.workspace == workspace }.count
        
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentWorkspace = workspace
                selectedItem = defaultItem
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: workspace.iconName)
                        .font(.title2)
                        .foregroundColor(workspace.themeColor)
                        .frame(width: 38, height: 38)
                        .background(workspace.themeColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(workspace.title)
                            .font(.headline.bold())
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text("\(toolCount) tools available")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                
                Text(workspace.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer(minLength: 4)
                
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Text("Launch Workspace")
                            .font(.caption.bold())
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.caption)
                    }
                    .foregroundColor(workspace.themeColor)
                }
            }
            .padding(16)
            .frame(height: 148)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(workspace.themeColor.opacity(0.4), lineWidth: 1.5)
            )
            .shadow(color: workspace.themeColor.opacity(0.08), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onHover { hovering in
            if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
    }
    
    @ViewBuilder
    private func sidebarLink(for item: NavigationItem) -> some View {
        NavigationLink(value: item) {
            HStack(spacing: compactNavigation ? 0 : 10) {
                Image(systemName: item.iconName)
                    .font(.body)
                    .frame(width: 18, alignment: .center)
                    .foregroundColor(item == .brewGhost ? .purple : .primary)
                if !compactNavigation || !sidebarSearch.isEmpty {
                    Text(item.title)
                        .font(.body.weight(item == .brewGhost ? .bold : .regular))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .truncationMode(.tail)
                    if item == .brewGhost {
                        Spacer()
                        Text("TOP")
                            .font(.system(size: 8, weight: .black))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.purple.opacity(0.18), in: Capsule())
                            .foregroundColor(.purple)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .help(item.title)
        .contextMenu {
            Button(navigationPreferences.isFavorite(item) ? "Remove from Favorites" : "Add to Favorites") {
                navigationPreferences.toggleFavorite(item)
            }
        }
    }
    
    @ViewBuilder
    private func creatorRepoLink(name: String, title: String, desc: String, icon: String, color: Color, tag: String? = nil) -> some View {
        Button(action: {
            if let url = URL(string: "https://github.com/\(name)") {
                NSWorkspace.shared.open(url)
            }
        }) {
            HStack(spacing: compactNavigation ? 0 : 8) {
                Image(systemName: icon)
                    .font(.body)
                    .frame(width: 16, alignment: .center)
                    .foregroundColor(color)
                if !compactNavigation {
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 4) {
                            Text(title)
                                .font(.caption.bold())
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            if let tag {
                                Text(tag)
                                    .font(.system(size: 8, weight: .black))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(color.opacity(0.18), in: Capsule())
                                    .foregroundColor(color)
                            }
                        }
                        Text(desc)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 2)
        .help("Open https://github.com/\(name) on GitHub")
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
