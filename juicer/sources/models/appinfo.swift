import Foundation
import AppKit

struct AppInfo: Identifiable, Hashable {
    let id: UUID = UUID()
    let appName: String
    let bundleIdentifier: String
    let path: URL
    let version: String
    
    // Hashable conformance based on bundle ID and path
    func hash(into hasher: inout Hasher) {
        hasher.combine(bundleIdentifier)
        hasher.combine(path)
    }
    
    static func == (lhs: AppInfo, rhs: AppInfo) -> Bool {
        return lhs.bundleIdentifier == rhs.bundleIdentifier && lhs.path == rhs.path
    }
    
    // Lazy icon retrieval to keep list scrolling highly performant
    var icon: NSImage {
        return NSWorkspace.shared.icon(forFile: path.path)
    }
    
    init(path: URL) {
        self.path = path
        
        let infoPlistURL = path.appendingPathComponent("Contents/Info.plist")
        let defaultName = path.deletingPathExtension().lastPathComponent
        
        if let plistDict = NSDictionary(contentsOf: infoPlistURL) {
            self.bundleIdentifier = plistDict["CFBundleIdentifier"] as? String ?? "unknown.\(defaultName.lowercased())"
            
            // Prioritize CFBundleDisplayName, then CFBundleName, fallback to file name
            if let displayName = plistDict["CFBundleDisplayName"] as? String, !displayName.isEmpty {
                self.appName = displayName
            } else if let bundleName = plistDict["CFBundleName"] as? String, !bundleName.isEmpty {
                self.appName = bundleName
            } else {
                self.appName = defaultName
            }
            
            self.version = plistDict["CFBundleShortVersionString"] as? String ?? plistDict["CFBundleVersion"] as? String ?? "1.0"
        } else {
            self.bundleIdentifier = "unknown.\(defaultName.lowercased())"
            self.appName = defaultName
            self.version = "1.0"
        }
    }
}
