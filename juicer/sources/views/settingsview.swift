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
            // Tab 1: General
            Form {
                Section(header: Text("App Notifications & Logs").bold()) {
                    Toggle("Enable completion banner notifications", isOn: $enableNotifications)
                    Picker("Console Logs Detail Level:", selection: $logLevel) {
                        Text("Standard Info").tag(0)
                        Text("Verbose Debugging").tag(1)
                    }
                }
                
                Section(header: Text("Startup").bold()) {
                    Picker("Default Launch View Panel:", selection: $launchTab) {
                        Text("Dashboard").tag("Dashboard")
                        Text("App Uninstaller").tag("App Uninstaller")
                        Text("Developer Caches").tag("Developer Caches")
                        Text("Service Manager").tag("Service Manager")
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showingResetAlert1 = true
                    } label: {
                        Label("Reset All Settings to Defaults", systemImage: "arrow.counterclockwise")
                    }
                    .padding(.top, 10)
                }
            }
            .tabItem { Label("General", systemImage: "gearshape") }
            .padding()
            
            // Tab 2: Uninstaller
            Form {
                Section(header: Text("Leftovers Deep Scan").bold()) {
                    Picker("Search Locations Scope Level:", selection: $uninstallerDepth) {
                        Text("Normal (Basic containers)").tag(0)
                        Text("Deep (Caches + Library targets)").tag(1)
                        Text("Extended (Receipts + Obscure folders)").tag(2)
                    }
                    .pickerStyle(.inline)
                }
                
                Section(header: Text("Application Library Indexes").bold()) {
                    Toggle("Auto-scan installed applications on launch", isOn: $autoScanApps)
                    Toggle("Prevent deletion of Apple system applications", isOn: $protectSystemApps)
                }
            }
            .tabItem { Label("Uninstaller", systemImage: "trash") }
            .padding()
            
            // Tab 3: Caches & Tweaks
            Form {
                Section(header: Text("Default Prune Targets Selection").bold()) {
                    HStack(spacing: 30) {
                        VStack(alignment: .leading) {
                            Toggle("Xcode DerivedData", isOn: $cleanXcode)
                            Toggle("NPM packages cache", isOn: $cleanNpm)
                            Toggle("Yarn cache folders", isOn: $cleanYarn)
                        }
                        VStack(alignment: .leading) {
                            Toggle("Bun temporary files", isOn: $cleanBun)
                            Toggle("Cargo build targets", isOn: $cleanCargo)
                            Toggle("Docker images/containers", isOn: $cleanDocker)
                        }
                    }
                }
                
                Section(header: Text("System Tweaks Action").bold()) {
                    Toggle("Auto-restart Finder/Dock after tweaks", isOn: $autoRestartShell)
                }
            }
            .tabItem { Label("Caches & Tweaks", systemImage: "hammer") }
            .padding()
            
            // Tab 4: Custom Rules lists
            VStack(spacing: 12) {
                Text("Custom Filters & Rules Manager")
                    .font(.headline)
                    .bold()
                Text("Configure custom paths or ignored lists to personalize scan results.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // 1. Ignored Paths
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Ignored Scanning Paths (e.g. bypass workspace folders)").bold()
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
                    }
                    .padding(5)
                }
            }
            .tabItem { Label("Custom Rules", systemImage: "list.bullet.rectangle.portrait") }
            .padding()
        }
        .frame(width: 580, height: 420)
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
