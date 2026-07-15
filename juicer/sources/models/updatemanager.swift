import Foundation
import Sparkle
import Combine

class UpdateManager: ObservableObject {
    static let shared = UpdateManager()
    
    private var updaterController: SPUStandardUpdaterController?
    
    @Published var canCheckForUpdates = false
    
    private init() {
        #if !DEBUG
        // Only run Sparkle updater in compiled app environment, bypassing unit tests
        if Bundle.main.bundleIdentifier == "com.even.juicer" {
            updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
            canCheckForUpdates = true
        }
        #else
        // Allow testing in debug
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        canCheckForUpdates = true
        #endif
    }
    
    func checkForUpdates() {
        updaterController?.checkForUpdates(nil)
    }
}
