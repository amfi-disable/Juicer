import SwiftUI

@main
struct juicerapp: App {
    var body: some Scene {
        WindowGroup {
            mainsidebarview()
                .frame(minWidth: 950, minHeight: 650)
        }
        .windowStyle(.hiddenTitleBar)
        
        Settings {
            settingsview()
        }
    }
}
