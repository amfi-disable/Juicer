import Foundation
import AppKit

struct LeftoverItem: Identifiable, Hashable {
    let id: UUID = UUID()
    let url: URL
    let size: Int64
    var isSelected: Bool
    let category: String // "Application Support", "Caches", "Preferences", etc.
    
    var path: String { url.path }
    var name: String { url.lastPathComponent }
}

class UninstallerManager: ObservableObject {
    @Published var appInfo: AppInfo?
    @Published var leftovers: [LeftoverItem] = []
    @Published var isScanning = false
    @Published var isRunning = false
    @Published var isTrashing = false
    @Published var installedApps: [AppInfo] = []
    
    private let fileManager = FileManager.default
    
    func scanInstalledApplications() {
        self.isScanning = true
        self.installedApps = []
        AppLogger.shared.log("Scanning system and user Applications folders...")
        
        Task.detached(priority: .userInitiated) {
            let scanPaths = [
                "/Applications",
                "/System/Applications",
                FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path
            ]
            
            var discovered: [AppInfo] = []
            let ignoredApps = UserDefaults.standard.stringArray(forKey: "juicer.settings.ignoredApps") ?? ["Safari", "Finder"]
            
            for path in scanPaths {
                let url = URL(fileURLWithPath: path)
                guard let enumerator = FileManager.default.enumerator(
                    at: url,
                    includingPropertiesForKeys: [.isApplicationKey],
                    options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]
                ) else { continue }
                
                for case let fileURL as URL in enumerator {
                    if fileURL.pathExtension == "app" {
                        let info = AppInfo(path: fileURL)
                        if !info.appName.isEmpty && !ignoredApps.contains(info.appName) {
                            discovered.append(info)
                        }
                    }
                }
            }
            
            let sorted = discovered.reduce(into: [AppInfo]()) { unique, app in
                if !unique.contains(where: { $0.path == app.path }) {
                    unique.append(app)
                }
            }.sorted(by: { $0.appName.localizedCompare(String($1.appName)) == .orderedAscending })
            
            await MainActor.run {
                self.installedApps = sorted
                self.isScanning = false
                AppLogger.shared.log("Found \(sorted.count) installed applications (excluding ignored ones).")
            }
        }
    }
    
    func checkRunningState(for app: AppInfo) {
        let runningApps = NSWorkspace.shared.runningApplications
        self.isRunning = runningApps.contains { runningApp in
            if let bundleId = runningApp.bundleIdentifier, bundleId == app.bundleIdentifier {
                return true
            }
            if runningApp.bundleURL == app.path {
                return true
            }
            return false
        }
    }
    
    func terminateApp(completion: @escaping (Bool) -> Void) {
        guard let app = appInfo else {
            completion(false)
            return
        }
        
        let runningApps = NSWorkspace.shared.runningApplications
        let targets = runningApps.filter { runningApp in
            runningApp.bundleIdentifier == app.bundleIdentifier || runningApp.bundleURL == app.path
        }
        
        guard !targets.isEmpty else {
            self.isRunning = false
            completion(true)
            return
        }
        
        let group = DispatchGroup()
        var allTerminated = true
        
        for target in targets {
            group.enter()
            AppLogger.shared.log("Attempting to terminate running process for \(app.appName)...")
            
            // Standard terminate
            target.terminate()
            
            // Wait briefly to see if it terminates, otherwise force kill
            DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                if !target.isTerminated {
                    AppLogger.shared.log("Process for \(app.appName) did not terminate. Force killing...")
                    target.forceTerminate()
                }
                
                // Final check
                DispatchQueue.main.async {
                    if !target.isTerminated {
                        allTerminated = false
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            self.isRunning = !allTerminated
            completion(allTerminated)
        }
    }
    
    func scan(for app: AppInfo) {
        self.appInfo = app
        self.leftovers = []
        self.isScanning = true
        
        checkRunningState(for: app)
        AppLogger.shared.log("Scanning leftovers for \(app.appName) (\(app.bundleIdentifier))...")
        
        Task.detached(priority: .userInitiated) {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            let depth = UserDefaults.standard.integer(forKey: "juicer.settings.uninstallerDepth")
            
            var searchLocations: [(category: String, path: String)] = []
            
            // Level 0: Normal
            searchLocations.append(contentsOf: [
                ("Application Support", "\(home)/Library/Application Support"),
                ("Caches", "\(home)/Library/Caches"),
                ("Containers", "\(home)/Library/Containers"),
                ("Group Containers", "\(home)/Library/Group Containers")
            ])
            
            // Level 1: Deep
            if depth >= 1 {
                searchLocations.append(contentsOf: [
                    ("Application Scripts", "\(home)/Library/Application Scripts"),
                    ("HTTPStorages", "\(home)/Library/HTTPStorages"),
                    ("Logs", "\(home)/Library/Logs"),
                    ("Preferences", "\(home)/Library/Preferences"),
                    ("Saved Application State", "\(home)/Library/Saved Application State"),
                    ("Global Application Support", "/Library/Application Support"),
                    ("Global Caches", "/Library/Caches")
                ])
            }
            
            // Level 2: Extended
            if depth >= 2 {
                searchLocations.append(contentsOf: [
                    ("LaunchAgents", "\(home)/Library/LaunchAgents"),
                    ("Global LaunchAgents", "/Library/LaunchAgents"),
                    ("Global LaunchDaemons", "/Library/LaunchDaemons"),
                    ("Global Preferences", "/Library/Preferences"),
                    ("Global Logs", "/Library/Logs"),
                    ("Package Receipts", "/private/var/db/receipts")
                ])
            }
            
            var discovered: [LeftoverItem] = []
            let protectSystem = UserDefaults.standard.bool(forKey: "juicer.settings.protectSystemApps")
            
            // Add the app binary itself if it's not a protected system app
            if FileManager.default.fileExists(atPath: app.path.path) {
                if protectSystem && app.path.path.hasPrefix("/System/Applications") {
                    AppLogger.shared.log("Protecting system application bundle from being removed: \(app.appName)")
                } else {
                    let size = self.getPathSize(app.path)
                    discovered.append(LeftoverItem(url: app.path, size: size, isSelected: true, category: "Application Bundle"))
                }
            }
            
            let bundleComponents = app.bundleIdentifier.split(separator: ".").map { String($0).lowercased() }
            let lastBundleComponent = bundleComponents.last ?? ""
            let appNameLower = app.appName.lowercased()
            
            let ignoredPaths = UserDefaults.standard.stringArray(forKey: "juicer.settings.ignoredPaths") ?? []
            
            for location in searchLocations {
                // Skip scan if this search directory starts with any ignored paths
                if ignoredPaths.contains(where: { location.path.hasPrefix($0) }) {
                    continue
                }
                
                guard let contents = try? FileManager.default.contentsOfDirectory(atPath: location.path) else {
                    continue
                }
                
                for item in contents {
                    let itemLower = item.lowercased()
                    let fullPath = URL(fileURLWithPath: location.path).appendingPathComponent(item)
                    
                    // Skip scan if item starts with any ignored paths
                    if ignoredPaths.contains(where: { fullPath.path.hasPrefix($0) }) {
                        continue
                    }
                    
                    var isMatch = false
                    
                    // Match 1: Bundle ID exact or prefix/suffix match
                    if itemLower.contains(app.bundleIdentifier.lowercased()) {
                        isMatch = true
                    }
                    // Match 2: App name exact or substring match
                    else if itemLower.contains(appNameLower) {
                        isMatch = true
                    }
                    // Match 3: Match on the last component of bundle identifier
                    else if !lastBundleComponent.isEmpty && itemLower == lastBundleComponent {
                        isMatch = true
                    }
                    
                    if isMatch {
                        // Skip system files
                        if item.hasPrefix("com.apple.") && !app.bundleIdentifier.hasPrefix("com.apple.") {
                            continue
                        }
                        
                        let size = self.getPathSize(fullPath)
                        discovered.append(LeftoverItem(url: fullPath, size: size, isSelected: true, category: location.category))
                    }
                }
            }
            
            await MainActor.run {
                self.leftovers = discovered.sorted(by: { $0.category < $1.category })
                self.isScanning = false
                AppLogger.shared.log("Scan complete. Found \(discovered.count) leftovers.")
            }
        }
    }
    
    func trashSelectedLeftovers(completion: @escaping (Bool) -> Void) {
        guard appInfo != nil else {
            completion(false)
            return
        }
        
        self.isTrashing = true
        let itemsToTrash = leftovers.filter { $0.isSelected }
        
        AppLogger.shared.log("Moving \(itemsToTrash.count) items to the Trash...")
        
        Task.detached(priority: .userInitiated) {
            var success = true
            
            for item in itemsToTrash {
                do {
                    if FileManager.default.fileExists(atPath: item.path) {
                        AppLogger.shared.log("Trashing: \(item.path)")
                        try FileManager.default.trashItem(at: item.url, resultingItemURL: nil)
                    }
                } catch {
                    AppLogger.shared.log("Failed to trash \(item.name): \(error.localizedDescription)")
                    success = false
                }
            }
            
            await MainActor.run {
                self.leftovers.removeAll { $0.isSelected }
                self.isTrashing = false
                AppLogger.shared.log("Cleanup finished.")
                completion(success)
            }
        }
    }
    
    private func getPathSize(_ url: URL) -> Int64 {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return 0
        }
        
        if isDirectory.boolValue {
            var size: Int64 = 0
            guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) else {
                return 0
            }
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    size += Int64(fileSize)
                }
            }
            return size
        } else {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
               let fileSize = attrs[.size] as? Int64 {
                return fileSize
            }
            return 0
        }
    }
}
