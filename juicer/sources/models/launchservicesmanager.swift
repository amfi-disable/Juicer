import Foundation
import ApplicationServices
import UniformTypeIdentifiers

struct AssociatedFileType: Identifiable, Hashable {
    let id: UUID = UUID()
    let fileExtension: String
    let uti: String
    var isCurrentlyDefault: Bool
}

class LaunchServicesManager: ObservableObject {
    @Published var selectedApp: AppInfo?
    @Published var fileTypes: [AssociatedFileType] = []
    @Published var isUpdating = false
    
    func loadFileTypes(for app: AppInfo) {
        self.selectedApp = app
        self.fileTypes = []
        
        let infoPlistURL = app.path.appendingPathComponent("Contents/Info.plist")
        guard let plistDict = NSDictionary(contentsOf: infoPlistURL),
              let docTypes = plistDict["CFBundleDocumentTypes"] as? [[String: Any]] else {
            AppLogger.shared.log("\(app.appName) does not declare support for any document types in its Info.plist.")
            return
        }
        
        var discovered: [AssociatedFileType] = []
        
        for doc in docTypes {
            let utis = doc["LSItemContentTypes"] as? [String] ?? []
            let extensions = doc["CFBundleTypeExtensions"] as? [String] ?? []
            
            // Map UTIs
            for uti in utis {
                let fileExt: String
                if let type = UTType(uti) {
                    fileExt = type.preferredFilenameExtension ?? ""
                } else {
                    fileExt = ""
                }
                
                let isDefault = checkIsDefault(uti: uti, appBundleId: app.bundleIdentifier)
                
                // Avoid duplicates
                if !discovered.contains(where: { $0.uti == uti }) {
                    discovered.append(AssociatedFileType(
                        fileExtension: fileExt.isEmpty ? "unknown" : fileExt,
                        uti: uti,
                        isCurrentlyDefault: isDefault
                    ))
                }
            }
            
            // Map raw extensions if UTIs are missing
            for ext in extensions {
                let uti: String
                if let type = UTType(filenameExtension: ext) {
                    uti = type.identifier
                } else {
                    uti = "public.data"
                }
                
                let isDefault = checkIsDefault(uti: uti, appBundleId: app.bundleIdentifier)
                
                if !discovered.contains(where: { $0.fileExtension == ext }) {
                    discovered.append(AssociatedFileType(
                        fileExtension: ext,
                        uti: uti,
                        isCurrentlyDefault: isDefault
                    ))
                }
            }
        }
        
        self.fileTypes = discovered.sorted(by: { $0.fileExtension < $1.fileExtension })
        AppLogger.shared.log("Loaded \(self.fileTypes.count) file extensions supported by \(app.appName).")
    }
    
    func setAsDefaultHandler(for item: AssociatedFileType, appBundleId: String) -> Bool {
        AppLogger.shared.log("Setting default handler for '\(item.fileExtension)' (\(item.uti)) to \(appBundleId)...")
        
        let status = LSSetDefaultRoleHandlerForContentType(
            item.uti as CFString,
            .all,
            appBundleId as CFString
        )
        
        let success = status == noErr
        if success {
            AppLogger.shared.log("Successfully bound \(item.fileExtension) to \(appBundleId).")
        } else {
            AppLogger.shared.log("Failed to override association. Error status: \(status)")
        }
        
        // Refresh local items
        if let app = selectedApp {
            loadFileTypes(for: app)
        }
        
        return success
    }
    
    private func checkIsDefault(uti: String, appBundleId: String) -> Bool {
        if let defaultHandler = LSCopyDefaultRoleHandlerForContentType(uti as CFString, .all)?.takeRetainedValue() as String? {
            return defaultHandler.lowercased() == appBundleId.lowercased()
        }
        return false
    }
}
