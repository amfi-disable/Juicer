import SwiftUI

@main
struct juicerapp: App {
    @State private var hasAccess: Bool = onboardingview.checkFullDiskAccess()

    init() {
        // Request notifications permission on app launch
        NotificationManager.shared.requestAuthorization()
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
