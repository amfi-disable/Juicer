import Foundation
import AppKit

class OrphanScannerManager: ObservableObject {
    @Published var orphans: [LeftoverItem] = []
    @Published var isScanning = false
    @Published var isTrashing = false
    
    private let fileManager = FileManager.default
    
    // System directories that should never be flagged as orphans
    private let systemSkipList = Set([
        "com.apple.appstore",
        "com.apple.finder",
        "com.apple.safari",
        "com.apple.mail",
        "com.apple.systempreferences",
        "com.apple.activitymonitor",
        "com.apple.terminal",
        "com.apple.textedit",
        "com.apple.keychainaccess",
        "com.apple.preview",
        "crashreporter",
        "icloud",
        "addressbook",
        "callhistorytemplates",
        "dock",
        "quicklook",
        "syncservices",
        "helper",
        "system",
        "microsoft", // Microsoft Shared / standard components
        "adobe"
    ])
    
    private func sanitize(_ string: String) -> String {
        return string.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
    }
    
    func scanOrphans() {
        self.orphans = []
        self.isScanning = true
        
        AppLogger.shared.log("Starting passive orphan scanner...")
        
        Task.detached(priority: .userInitiated) {
            // Step 1: Scan all installed apps to collect active names and bundle identifiers
            let appDirs = [
                "/Applications",
                "/System/Applications",
                "\(FileManager.default.homeDirectoryForCurrentUser.path)/Applications"
            ]
            
            var activeAppNames = Set<String>()
            var activeBundleIds = Set<String>()
            var sanitizedSignatures = Set<String>()
            
            for appDir in appDirs {
                guard let contents = try? FileManager.default.contentsOfDirectory(atPath: appDir) else {
                    continue
                }
                
                for item in contents where item.hasSuffix(".app") {
                    let appPath = URL(fileURLWithPath: appDir).appendingPathComponent(item)
                    let info = AppInfo(path: appPath)
                    
                    activeAppNames.insert(info.appName.lowercased())
                    activeBundleIds.insert(info.bundleIdentifier.lowercased())
                    
                    // Add sanitized name signatures
                    sanitizedSignatures.insert(self.sanitize(info.appName))
                    let rawAppName = item.replacingOccurrences(of: ".app", with: "")
                    sanitizedSignatures.insert(self.sanitize(rawAppName))
                    
                    // Also insert last component of bundle ID as an active signifier
                    let bundleParts = info.bundleIdentifier.split(separator: ".").map { String($0).lowercased() }
                    if let lastPart = bundleParts.last {
                        activeAppNames.insert(lastPart)
                        sanitizedSignatures.insert(self.sanitize(lastPart))
                    }
                }
            }
            
            // Step 2: Scan library subdirectories
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            let libraryPaths = [
                (category: "Application Support", path: "\(home)/Library/Application Support"),
                (category: "Containers", path: "\(home)/Library/Containers")
            ]
            
            var detectedOrphans: [LeftoverItem] = []
            
            for library in libraryPaths {
                guard let contents = try? FileManager.default.contentsOfDirectory(atPath: library.path) else {
                    continue
                }
                
                for item in contents {
                    let itemLower = item.lowercased()
                    let sanitizedItem = self.sanitize(item)
                    
                    // Skip system skip lists and macOS internal files
                    if item.hasPrefix(".") || item.hasPrefix("com.apple.") || self.systemSkipList.contains(itemLower) {
                        continue
                    }
                    
                    let fullPath = URL(fileURLWithPath: library.path).appendingPathComponent(item)
                    
                    // Match check: Is this directory related to any installed application?
                    var matchesAnyApp = false
                    
                    // Check direct bundle ID matches
                    if activeBundleIds.contains(itemLower) {
                        matchesAnyApp = true
                    }
                    
                    // Check contains app names or bundle ID subcomponents
                    if !matchesAnyApp {
                        for appName in activeAppNames {
                            if itemLower == appName || itemLower.contains(".\(appName)") || itemLower.contains("\(appName).") {
                                matchesAnyApp = true
                                break
                            }
                        }
                    }
                    
                    // Check fuzzy sanitized signatures
                    if !matchesAnyApp {
                        for signature in sanitizedSignatures {
                            if sanitizedItem == signature || sanitizedItem.contains(signature) || signature.contains(sanitizedItem) {
                                matchesAnyApp = true
                                break
                            }
                        }
                    }
                    
                    // If no match was found, we have found an orphan!
                    if !matchesAnyApp {
                        let size = self.getPathSize(fullPath)
                        // Skip tiny/empty directories (less than 1KB) to keep results clean
                        if size > 1024 {
                            detectedOrphans.append(LeftoverItem(
                                url: fullPath,
                                size: size,
                                isSelected: true,
                                category: library.category
                             ))
                        }
                    }
                }
            }
            
            await MainActor.run {
                self.orphans = detectedOrphans.sorted(by: { $0.size > $1.size })
                self.isScanning = false
                AppLogger.shared.log("Orphan scan complete. Found \(self.orphans.count) orphaned directories.")
            }
        }
    }
    
    func trashSelectedOrphans(completion: @escaping (Bool) -> Void) {
        self.isTrashing = true
        let itemsToTrash = orphans.filter { $0.isSelected }
        
        AppLogger.shared.log("Moving \(itemsToTrash.count) orphaned folders to the Trash...")
        
        Task.detached(priority: .userInitiated) {
            var success = true
            
            for item in itemsToTrash {
                do {
                    if FileManager.default.fileExists(atPath: item.path) {
                        AppLogger.shared.log("Trashing orphan: \(item.path)")
                        try FileManager.default.trashItem(at: item.url, resultingItemURL: nil)
                    }
                } catch {
                    AppLogger.shared.log("Failed to trash orphan \(item.name): \(error.localizedDescription)")
                    success = false
                }
            }
            
            await MainActor.run {
                self.orphans.removeAll { $0.isSelected }
                self.isTrashing = false
                AppLogger.shared.log("Orphan cleanup finished.")
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
