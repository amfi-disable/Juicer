import Foundation
import AppKit

class TrashObserver: ObservableObject {
    static let shared = TrashObserver()
    
    private var timer: Timer?
    private var knownAppsInTrash: Set<String> = []
    private let fm = FileManager.default
    
    private var trashURL: URL {
        fm.urls(for: .trashDirectory, in: .allDomainsMask).first ?? 
        URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".Trash")
    }
    
    func startObserving() {
        // Initial scan
        knownAppsInTrash = scanAppsInTrash()
        
        // Start polling every 3 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.checkTrash()
        }
    }
    
    func stopObserving() {
        timer?.invalidate()
        timer = nil
    }
    
    private func scanAppsInTrash() -> Set<String> {
        guard let contents = try? fm.contentsOfDirectory(atPath: trashURL.path) else {
            return []
        }
        let apps = contents.filter { $0.hasSuffix(".app") }
        return Set(apps)
    }
    
    private func checkTrash() {
        let currentApps = scanAppsInTrash()
        let newlyAdded = currentApps.subtracting(knownAppsInTrash)
        
        if !newlyAdded.isEmpty {
            for appName in newlyAdded {
                let appURL = trashURL.appendingPathComponent(appName)
                AppLogger.shared.log("Trash observer detected newly trashed application: \(appName)")
                
                // Fire native user notification
                NotificationManager.shared.sendNotification(
                    title: "Application Trashed: Leftovers Found",
                    body: "Juicer found leftovers for \(appName.replacingOccurrences(of: ".app", with: "")). Click to scan and delete."
                )
                
                // Post internal notification to navigate to app uninstaller with this path
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("juicer.nav.uninstaller.scan"),
                        object: appURL
                    )
                }
            }
        }
        
        knownAppsInTrash = currentApps
    }
}
