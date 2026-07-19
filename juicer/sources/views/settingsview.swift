import SwiftUI
import AppKit

class SettingsManager: ObservableObject {
    @Published var ignoredPaths: [String] = []
    @Published var customCachePaths: [String] = []
    @Published var ignoredApps: [String] = []
    
    private let ignoredPathsKey = "juicer.settings.ignoredPaths"
    private let customCachePathsKey = "juicer.settings.customCachePaths"
    private let ignoredAppsKey = "juicer.settings.ignoredApps"
    
    init() {
        loadSettings()
        if UserDefaults.standard.object(forKey: "juicer.settings.enableNotifications") == nil {
            resetAllToDefaults()
        }
    }
    
    func loadSettings() {
        self.ignoredPaths = UserDefaults.standard.stringArray(forKey: ignoredPathsKey) ?? ["/System/Library", "/Library/Updates"]
        self.customCachePaths = UserDefaults.standard.stringArray(forKey: customCachePathsKey) ?? []
        self.ignoredApps = UserDefaults.standard.stringArray(forKey: ignoredAppsKey) ?? ["Safari", "Finder"]
    }
    
    func saveSettings() {
        UserDefaults.standard.set(ignoredPaths, forKey: ignoredPathsKey)
        UserDefaults.standard.set(customCachePaths, forKey: customCachePathsKey)
        UserDefaults.standard.set(ignoredApps, forKey: ignoredAppsKey)
    }
    
    func addIgnoredPath(_ path: String) {
        let clean = path.trimmingCharacters(in: .whitespacesAndNewlines)
        if !clean.isEmpty && !ignoredPaths.contains(clean) {
            ignoredPaths.append(clean)
            saveSettings()
        }
    }
    
    func removeIgnoredPath(_ path: String) {
        ignoredPaths.removeAll { $0 == path }
        saveSettings()
    }
    
    func addCustomCachePath(_ path: String) {
        let clean = path.trimmingCharacters(in: .whitespacesAndNewlines)
        if !clean.isEmpty && !customCachePaths.contains(clean) {
            customCachePaths.append(clean)
            saveSettings()
        }
    }
    
    func removeCustomCachePath(_ path: String) {
        customCachePaths.removeAll { $0 == path }
        saveSettings()
    }
    
    func addIgnoredApp(_ app: String) {
        let clean = app.trimmingCharacters(in: .whitespacesAndNewlines)
        if !clean.isEmpty && !ignoredApps.contains(clean) {
            ignoredApps.append(clean)
            saveSettings()
        }
    }
    
    func removeIgnoredApp(_ app: String) {
        ignoredApps.removeAll { $0 == app }
        saveSettings()
    }
    
    func resetAllToDefaults() {
        // General defaults
        UserDefaults.standard.set(true, forKey: "juicer.settings.enableNotifications")
        UserDefaults.standard.set("Dashboard", forKey: "juicer.settings.launchTab")
        UserDefaults.standard.set(0, forKey: "juicer.settings.logLevel")
        
        // Uninstaller defaults
        UserDefaults.standard.set(1, forKey: "juicer.settings.uninstallerDepth") // 0: Normal, 1: Deep, 2: Extended
        UserDefaults.standard.set(true, forKey: "juicer.settings.autoScanApps")
        UserDefaults.standard.set(true, forKey: "juicer.settings.protectSystemApps")
        
        // Caches defaults
        UserDefaults.standard.set(true, forKey: "juicer.settings.cleanXcodeDefault")
        UserDefaults.standard.set(true, forKey: "juicer.settings.cleanNpmDefault")
        UserDefaults.standard.set(true, forKey: "juicer.settings.cleanYarnDefault")
        UserDefaults.standard.set(true, forKey: "juicer.settings.cleanBunDefault")
        UserDefaults.standard.set(true, forKey: "juicer.settings.cleanCargoDefault")
        UserDefaults.standard.set(true, forKey: "juicer.settings.cleanDockerDefault")
        
        // Network defaults
        UserDefaults.standard.set(false, forKey: "juicer.settings.killForceful")
        UserDefaults.standard.set(true, forKey: "juicer.settings.defaultToDevPorts")
        UserDefaults.standard.set(true, forKey: "juicer.settings.showProcessArgs")
        
        // System Tweaks defaults
        UserDefaults.standard.set(true, forKey: "juicer.settings.autoRestartShell")

        // Control Center defaults
        UserDefaults.standard.set(true, forKey: "juicer.settings.showStatusMenuBar")
        UserDefaults.standard.set(true, forKey: "juicer.settings.showQuickSendMenuBar")
        UserDefaults.standard.set("label", forKey: "juicer.settings.menuBarLabelStyle")
        UserDefaults.standard.set(false, forKey: "juicer.settings.launchAtLogin")
        UserDefaults.standard.set(true, forKey: "juicer.settings.confirmDestructiveActions")
        UserDefaults.standard.set(true, forKey: "juicer.settings.restoreMainWindow")
        UserDefaults.standard.set(true, forKey: "juicer.settings.showStatusBar")
        UserDefaults.standard.set("2s", forKey: "juicer.settings.statusMonitorRefresh")
        UserDefaults.standard.set("system", forKey: "juicer.settings.appearance")
        UserDefaults.standard.set("orange", forKey: "juicer.settings.accentColor")
        UserDefaults.standard.set(240, forKey: "juicer.settings.sidebarWidth")
        UserDefaults.standard.set(true, forKey: "juicer.dashboard.showVitals")
        UserDefaults.standard.set(true, forKey: "juicer.dashboard.showCuratedTools")
        UserDefaults.standard.set(true, forKey: "juicer.dashboard.showBookmarks")
        UserDefaults.standard.set(true, forKey: "juicer.settings.backgroundChecks")
        UserDefaults.standard.set(true, forKey: "juicer.settings.lowDiskAlerts")
        UserDefaults.standard.set(true, forKey: "juicer.settings.updateAlerts")
        UserDefaults.standard.set(3600, forKey: "juicer.settings.backgroundInterval")
        
        // Lists defaults
        self.ignoredPaths = ["/System/Library", "/Library/Updates", "/private/var"]
        self.customCachePaths = []
        self.ignoredApps = ["Safari", "Finder"]
        saveSettings()
    }
}

struct settingsview: View {
    @StateObject private var settingsManager = SettingsManager()
    
    // Binding parameters mapped to standard app storage
    @AppStorage("juicer.settings.enableNotifications") private var enableNotifications = true
    @AppStorage("juicer.settings.launchTab") private var launchTab = "Dashboard"
    @AppStorage("juicer.settings.logLevel") private var logLevel = 0
    
    @AppStorage("juicer.settings.uninstallerDepth") private var uninstallerDepth = 1
    @AppStorage("juicer.settings.autoScanApps") private var autoScanApps = true
    @AppStorage("juicer.settings.protectSystemApps") private var protectSystemApps = true
    
    @AppStorage("juicer.settings.cleanXcodeDefault") private var cleanXcode = true
    @AppStorage("juicer.settings.cleanNpmDefault") private var cleanNpm = true
    @AppStorage("juicer.settings.cleanYarnDefault") private var cleanYarn = true
    @AppStorage("juicer.settings.cleanBunDefault") private var cleanBun = true
    @AppStorage("juicer.settings.cleanCargoDefault") private var cleanCargo = true
    @AppStorage("juicer.settings.cleanDockerDefault") private var cleanDocker = true
    
    @AppStorage("juicer.settings.killForceful") private var killForceful = false
    @AppStorage("juicer.settings.defaultToDevPorts") private var defaultToDevPorts = true
    @AppStorage("juicer.settings.showProcessArgs") private var showProcessArgs = true
    
    @AppStorage("juicer.settings.autoRestartShell") private var autoRestartShell = true
    
    // Input parameters for Lists
    @State private var inputIgnoredPath = ""
    @State private var inputCustomCache = ""
    @State private var inputIgnoredApp = ""
    
    // Reset confirmation variables
    @State private var showingResetAlert1 = false
    @State private var showingResetAlert2 = false
    
    var body: some View {
        TabView {
            controlcenterview()
                .tabItem { Label("Control Center", systemImage: "switch.2") }

            // Tab 1: General
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("General App Configurations")
                        .font(.title3)
                        .bold()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Enable completion banner notifications", isOn: $enableNotifications)
                            .toggleStyle(.checkbox)
                        
                        Picker("Console Logs Detail Level:", selection: $logLevel) {
                            Text("Standard Info").tag(0)
                            Text("Verbose Debugging").tag(1)
                        }
                        .pickerStyle(.inline)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                    .cornerRadius(8)
                    
                    Text("Startup Preferences")
                        .font(.headline)
                        .bold()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Default Launch View Panel:", selection: $launchTab) {
                            Text("Dashboard").tag("Dashboard")
                            Text("App Uninstaller").tag("App Uninstaller")
                            Text("Developer Caches").tag("Developer Caches")
                            Text("Service Manager").tag("Service Manager")
                        }
                        .pickerStyle(.menu)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                    .cornerRadius(8)
                    
                    Text("Updates")
                        .font(.headline)
                        .bold()

                    VStack(alignment: .leading, spacing: 12) {
                        Button(action: { UpdateManager.shared.checkForUpdates() }) {
                            Label("Check for App Updates...", systemImage: "arrow.down.asymmetric.and.arrow.up.asymmetric")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                    .cornerRadius(8)

                    Spacer(minLength: 20)

                    Button(role: .destructive) {
                        showingResetAlert1 = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset All Settings to Defaults")
                        }
                        .foregroundColor(.red)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .tabItem { Label("General", systemImage: "gearshape") }
            
            // Tab 2: Uninstaller
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Uninstaller & Scan Settings")
                        .font(.title3)
                        .bold()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Search Locations Scope Level:")
                            .font(.headline)
                        
                        Picker("", selection: $uninstallerDepth) {
                            Text("Normal (Basic containers)").tag(0)
                            Text("Deep (Caches + Library targets)").tag(1)
                            Text("Extended (Receipts + Obscure folders)").tag(2)
                        }
                        .pickerStyle(.radioGroup)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                    .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Application Library Indexes:")
                            .font(.headline)
                        
                        Toggle("Auto-scan installed applications on launch", isOn: $autoScanApps)
                            .toggleStyle(.checkbox)
                        Toggle("Prevent deletion of Apple system applications", isOn: $protectSystemApps)
                            .toggleStyle(.checkbox)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                    .cornerRadius(8)
                }
                .padding()
            }
            .tabItem { Label("Uninstaller", systemImage: "trash") }
            
            // Tab 3: Caches & Tweaks
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Caches & System Tweaks")
                        .font(.title3)
                        .bold()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Default Prune Targets Selection:")
                            .font(.headline)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            Toggle("Xcode DerivedData", isOn: $cleanXcode)
                            Toggle("NPM packages cache", isOn: $cleanNpm)
                            Toggle("Yarn cache folders", isOn: $cleanYarn)
                            Toggle("Bun temporary files", isOn: $cleanBun)
                            Toggle("Cargo build targets", isOn: $cleanCargo)
                            Toggle("Docker images/containers", isOn: $cleanDocker)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                    .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("System Tweaks Action:")
                            .font(.headline)
                        
                        Toggle("Auto-restart Finder/Dock after tweaks", isOn: $autoRestartShell)
                            .toggleStyle(.checkbox)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                    .cornerRadius(8)
                }
                .padding()
            }
            .tabItem { Label("Caches & Tweaks", systemImage: "hammer") }
            
            // Tab 4: Custom Rules lists
            VStack(spacing: 12) {
                Text("Custom Filters & Rules Manager")
                    .font(.title3)
                    .bold()
                Text("Configure custom paths, bypassed applications, or custom cache folders.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // 1. Ignored Paths
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Ignored Scanning Paths (e.g. bypass directories)").bold()
                            HStack {
                                TextField("Enter directory path...", text: $inputIgnoredPath)
                                    .textFieldStyle(.roundedBorder)
                                Button("Add") {
                                    settingsManager.addIgnoredPath(inputIgnoredPath)
                                    inputIgnoredPath = ""
                                }
                                Button("Browse...") {
                                    let panel = NSOpenPanel()
                                    panel.canChooseDirectories = true
                                    panel.canChooseFiles = false
                                    panel.allowsMultipleSelection = false
                                    if panel.runModal() == .OK, let url = panel.url {
                                        settingsManager.addIgnoredPath(url.path)
                                    }
                                }
                            }
                            
                            ForEach(settingsManager.ignoredPaths, id: \.self) { path in
                                listRow(item: path, onRemove: { settingsManager.removeIgnoredPath(path) })
                            }
                        }
                        
                        Divider()
                        
                        // 2. Custom Cache Locations
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Custom Pruning Cache Folders (add custom build caches)").bold()
                            HStack {
                                TextField("Enter cache path...", text: $inputCustomCache)
                                    .textFieldStyle(.roundedBorder)
                                Button("Add") {
                                    settingsManager.addCustomCachePath(inputCustomCache)
                                    inputCustomCache = ""
                                }
                                Button("Browse...") {
                                    let panel = NSOpenPanel()
                                    panel.canChooseDirectories = true
                                    panel.canChooseFiles = false
                                    panel.allowsMultipleSelection = false
                                    if panel.runModal() == .OK, let url = panel.url {
                                        settingsManager.addCustomCachePath(url.path)
                                    }
                                }
                            }
                            
                            ForEach(settingsManager.customCachePaths, id: \.self) { path in
                                listRow(item: path, onRemove: { settingsManager.removeCustomCachePath(path) })
                            }
                        }
                        
                        Divider()
                        
                        // 3. Ignored Applications
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Ignored Scan Applications (ignored by Uninstaller)").bold()
                            HStack {
                                TextField("Enter application name (e.g. Safari)...", text: $inputIgnoredApp)
                                    .textFieldStyle(.roundedBorder)
                                Button("Add") {
                                    settingsManager.addIgnoredApp(inputIgnoredApp)
                                    inputIgnoredApp = ""
                                }
                            }
                            
                            ForEach(settingsManager.ignoredApps, id: \.self) { app in
                                listRow(item: app, onRemove: { settingsManager.removeIgnoredApp(app) })
                            }
                        }
                    }
                    .padding(5)
                }
            }
            .tabItem { Label("Custom Rules", systemImage: "list.bullet.rectangle.portrait") }
            .padding()

            helpview()
                .tabItem { Label("Help", systemImage: "questionmark.circle") }
        }
        .frame(width: 760, height: 530)
        // First Confirmation Alert
        .alert("Reset Settings to Defaults?", isPresented: $showingResetAlert1) {
            Button("Proceed", role: .none) {
                showingResetAlert2 = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to clear all your custom configurations and reset all settings to defaults?")
        }
        // Second Confirmation Alert
        .alert("Are you absolutely sure?", isPresented: $showingResetAlert2) {
            Button("Reset Everything", role: .destructive) {
                settingsManager.resetAllToDefaults()
                NotificationCenter.default.post(name: NSNotification.Name("juicer.settings.reset"), object: nil)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently wipe all customization preferences, ignored paths, and custom folders list. This cannot be undone.")
        }
    }
    
    @ViewBuilder
    private func listRow(item: String, onRemove: @escaping () -> Void) -> some View {
        HStack {
            Text(item)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            Button(action: onRemove) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 6)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(4)
    }
}
