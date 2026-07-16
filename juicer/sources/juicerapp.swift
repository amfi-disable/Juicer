import SwiftUI

@main
struct juicerapp: App {
    @State private var hasAccess: Bool = onboardingview.checkFullDiskAccess()

    init() {
        NotificationManager.shared.requestAuthorization()
        setupBackgroundScheduler()
    }
    
    private func setupBackgroundScheduler() {
        // Run background checks every hour
        Timer.scheduledTimer(withTimeInterval: 3600.0, repeats: true) { _ in
            self.performBackgroundScanAndAlert()
        }
        
        // Also run a check 10 seconds after launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            self.performBackgroundScanAndAlert()
        }
    }
    
    private func performBackgroundScanAndAlert() {
        // 1. Disk usage warning
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/"),
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
    }
}
