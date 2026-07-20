import SwiftUI

@main
struct juicerapp: App {
    @State private var hasAccess: Bool = onboardingview.checkFullDiskAccess()
    @AppStorage("juicer.settings.showStatusMenuBar") private var showStatusMenuBar = true
    @AppStorage("juicer.settings.showQuickSendMenuBar") private var showQuickSendMenuBar = true
    @AppStorage("juicer.settings.menuBarLabelStyle") private var menuBarLabelStyle = "label"

    init() {
        setenv("OS_ACTIVITY_MODE", "disable", 1)
        if UserDefaults.standard.object(forKey: "juicer.settings.enableNotifications") as? Bool ?? true {
            NotificationManager.shared.requestAuthorization()
        }
        setupBackgroundScheduler()
    }
    
    private func setupBackgroundScheduler() {
        let interval = UserDefaults.standard.double(forKey: "juicer.settings.backgroundInterval") > 0
            ? UserDefaults.standard.double(forKey: "juicer.settings.backgroundInterval")
            : 3600.0

        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            guard !(UserDefaults.standard.object(forKey: "juicer.settings.safeMode") as? Bool ?? false),
                  UserDefaults.standard.object(forKey: "juicer.settings.backgroundChecks") as? Bool ?? true else { return }
            self.performBackgroundScanAndAlert()
        }
        
        // Also run a check 10 seconds after launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            guard !(UserDefaults.standard.object(forKey: "juicer.settings.safeMode") as? Bool ?? false),
                  UserDefaults.standard.object(forKey: "juicer.settings.backgroundChecks") as? Bool ?? true else { return }
            self.performBackgroundScanAndAlert()
        }
    }
    
    private func performBackgroundScanAndAlert() {
        // 1. Disk usage warning
        if (UserDefaults.standard.object(forKey: "juicer.settings.lowDiskAlerts") as? Bool ?? true),
           let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/"),
           let total = attrs[.systemSize] as? Int64,
           let free = attrs[.systemFreeSize] as? Int64 {
            let usedPercent = Double(total - free) / Double(total)
            if usedPercent > 0.88 {
                let freeGB = free / 1_000_000_000
                NotificationManager.shared.sendNotification(
                    title: "Juicer Low Disk Space Warning",
                    body: "Only \(freeGB) GB remaining. Reclaim space via Cache Cleaner or Disk Visualizer."
                )
            }
        }
        
        // 2. Package updates check
        guard UserDefaults.standard.object(forKey: "juicer.settings.updateAlerts") as? Bool ?? true else { return }
        let manager = AppUpdateManager.shared
        manager.checkForUpdates()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            if !manager.updates.isEmpty {
                NotificationManager.shared.sendNotification(
                    title: "Software Updates Available",
                    body: "Juicer found \(manager.updates.count) packages waiting to be upgraded."
                )
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if hasAccess {
                mainsidebarview()
                    .frame(minWidth: 950, minHeight: 650)
            } else {
                onboardingview(isAccessGranted: $hasAccess)
                    .frame(width: 800, height: 600)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1180, height: 760)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    UpdateManager.shared.checkForUpdates()
                }
            }

            // Sidebar toggle command (native macOS sidebar control)
            SidebarCommands()
            
            // Custom File Commands
            CommandGroup(replacing: .newItem) {
                Button("Add Bookmark...") {
                    NotificationCenter.default.post(name: NSNotification.Name("juicer.action.addBookmark"), object: nil)
                }
                .keyboardShortcut("b", modifiers: [.command, .shift])
            }
            
            // Custom View Commands
            CommandGroup(before: .sidebar) {
                Button("Refresh Selected Tool") {
                    NotificationCenter.default.post(name: NSNotification.Name("juicer.action.refresh"), object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command])

                Button("Command Palette…") {
                    NotificationCenter.default.post(name: NSNotification.Name("juicer.action.commandPalette"), object: nil)
                }
                .keyboardShortcut("k", modifiers: [.command])
                
                Divider()
                
                Menu("Navigation") {
                    Button("Go to Dashboard") {
                        NotificationCenter.default.post(name: NSNotification.Name("juicer.nav.dashboard"), object: nil)
                    }
                    .keyboardShortcut("1", modifiers: [.command])
                    
                    Button("Go to App Uninstaller") {
                        NotificationCenter.default.post(name: NSNotification.Name("juicer.nav.uninstaller"), object: nil)
                    }
                    .keyboardShortcut("2", modifiers: [.command])
                    
                    Button("Go to Orphan Finder") {
                        NotificationCenter.default.post(name: NSNotification.Name("juicer.nav.orphans"), object: nil)
                    }
                    .keyboardShortcut("3", modifiers: [.command])
                    
                    Button("Go to Developer Caches") {
                        NotificationCenter.default.post(name: NSNotification.Name("juicer.nav.caches"), object: nil)
                    }
                    .keyboardShortcut("4", modifiers: [.command])
                    
                    Button("Go to Large & Old Files") {
                        NotificationCenter.default.post(name: NSNotification.Name("juicer.nav.largeFiles"), object: nil)
                    }
                    .keyboardShortcut("5", modifiers: [.command])
                    
                    Button("Go to Hidden File Explorer") {
                        NotificationCenter.default.post(name: NSNotification.Name("juicer.nav.hiddenFiles"), object: nil)
                    }
                    .keyboardShortcut("6", modifiers: [.command])
                    
                    Button("Go to Homebrew Explorer") {
                        NotificationCenter.default.post(name: NSNotification.Name("juicer.nav.brewExplorer"), object: nil)
                    }
                    .keyboardShortcut("7", modifiers: [.command])
                    
                    Button("Go to Service Manager") {
                        NotificationCenter.default.post(name: NSNotification.Name("juicer.nav.serviceManager"), object: nil)
                    }
                    .keyboardShortcut("8", modifiers: [.command])
                    
                    Button("Go to System Tweaks") {
                        NotificationCenter.default.post(name: NSNotification.Name("juicer.nav.systemTweaks"), object: nil)
                    }
                    .keyboardShortcut("9", modifiers: [.command])
                    
                    Divider()
                    
                    Button("Go to Software Center") {
                        NotificationCenter.default.post(name: NSNotification.Name("juicer.nav.appStore"), object: nil)
                    }
                    .keyboardShortcut("a", modifiers: [.command, .shift])
                    
                    Button("Go to Diagnostic Snapshots") {
                        NotificationCenter.default.post(name: NSNotification.Name("juicer.nav.snapshots"), object: nil)
                    }
                    .keyboardShortcut("d", modifiers: [.command, .shift])
                    
                    Button("Go to Script Console") {
                        NotificationCenter.default.post(name: NSNotification.Name("juicer.nav.scriptConsole"), object: nil)
                    }
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                    
                    Button("Go to Utilities Settings") {
                        NotificationCenter.default.post(name: NSNotification.Name("juicer.nav.utilities"), object: nil)
                    }
                    .keyboardShortcut("u", modifiers: [.command, .shift])
                }
            }
            
            // Custom Help Commands
            CommandGroup(replacing: .help) {
                Button("Juicer Help Manual") {
                    NotificationCenter.default.post(name: NSNotification.Name("juicer.action.showGuide"), object: nil)
                }
                .keyboardShortcut("?", modifiers: [.command])
                
                Button("Submit Feedback...") {
                    if let url = URL(string: "https://github.com/amfi-disable/Juicer/issues") {
                        NSWorkspace.shared.open(url)
                    }
                }
                
                Button("View Online Documentation") {
                    if let url = URL(string: "https://github.com/amfi-disable/Juicer") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
        
        Settings {
            settingsview()
        }

        MenuBarExtra(isInserted: $showQuickSendMenuBar) {
            airdropquicksendview()
                .frame(width: 360, height: 430)
        } label: {
            menuBarLabel(title: "AirDrop Quick-Send", icon: "airplayaudio")
        }
        .menuBarExtraStyle(.window)

        MenuBarExtra(isInserted: $showStatusMenuBar) {
            menubarmonitorview()
        } label: {
            menuBarLabel(title: "Juicer Status", icon: "waveform.path.ecg")
        }
        .menuBarExtraStyle(.window)
    }

    @ViewBuilder
    private func menuBarLabel(title: String, icon: String) -> some View {
        if menuBarLabelStyle == "icon" {
            Image(systemName: icon)
        } else {
            Label(title, systemImage: icon)
        }
    }
}
