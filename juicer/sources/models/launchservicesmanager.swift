import Foundation
import ApplicationServices
import UniformTypeIdentifiers
import AppKit

struct AssociatedFileType: Identifiable, Hashable {
    let id: UUID = UUID()
    let fileExtension: String
    let uti: String
    var isCurrentlyDefault: Bool
}

struct GlobalAssociationItem: Identifiable, Hashable {
    let id: UUID = UUID()
    let fileExtension: String
    let uti: String
    var handlerBundleId: String
    var handlerAppName: String
    var handlerIcon: NSImage?
}

class LaunchServicesManager: ObservableObject {
    @Published var selectedApp: AppInfo?
    @Published var fileTypes: [AssociatedFileType] = []
    @Published var globalAssociations: [GlobalAssociationItem] = []
    @Published var isUpdating = false
    
    // Preset developer extensions to query globally
    private let commonExtensions = [
        "txt", "rtf", "html", "css", "js", "ts", "json", "py", "rs", "go",
        "swift", "c", "cpp", "h", "sh", "xml", "yml", "yaml", "md", "java",
        "kt", "rb", "php", "sql", "csv", "tsv", "plist", "zip", "tar", "gz", "pdf",
        "png", "jpg", "jpeg", "gif", "svg", "webp", "mp4", "mp3"
    ]
    
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
            
            for uti in utis {
                let fileExt: String
                if let type = UTType(uti) {
                    fileExt = type.preferredFilenameExtension ?? ""
                } else {
                    fileExt = ""
                }
                
                let isDefault = checkIsDefault(uti: uti, appBundleId: app.bundleIdentifier)
                
                if !discovered.contains(where: { $0.uti == uti }) {
                    discovered.append(AssociatedFileType(
                        fileExtension: fileExt.isEmpty ? "unknown" : fileExt,
                        uti: uti,
                        isCurrentlyDefault: isDefault
                    ))
                }
            }
            
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
    
    func loadGlobalAssociations() {
        self.isUpdating = true
        self.globalAssociations = []
        AppLogger.shared.log("Querying global default applications from LaunchServices...")
        
        Task.detached(priority: .userInitiated) {
            var items: [GlobalAssociationItem] = []
            
            for ext in self.commonExtensions {
                let uti: String
                if let type = UTType(filenameExtension: ext) {
                    uti = type.identifier
                } else {
                    uti = "public.data"
                }
                
                var handlerBundleId = "None"
                var handlerAppName = "None"
                var handlerIcon: NSImage? = nil
                
                if let defaultHandler = LSCopyDefaultRoleHandlerForContentType(uti as CFString, .all)?.takeRetainedValue() as String? {
                    handlerBundleId = defaultHandler
                    
                    if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: defaultHandler) {
                        handlerAppName = appURL.deletingPathExtension().lastPathComponent
                        handlerIcon = NSWorkspace.shared.icon(forFile: appURL.path)
                    } else {
                        handlerAppName = defaultHandler
                    }
                }
                
                items.append(GlobalAssociationItem(
                    fileExtension: ext,
                    uti: uti,
                    handlerBundleId: handlerBundleId,
                    handlerAppName: handlerAppName,
                    handlerIcon: handlerIcon
                ))
            }
            
            await MainActor.run {
                self.globalAssociations = items
                self.isUpdating = false
                AppLogger.shared.log("Loaded \(items.count) global file associations.")
            }
        }
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
        
        if let app = selectedApp {
            loadFileTypes(for: app)
        }
        
        return success
    }
    
    func setGlobalDefaultHandler(for item: GlobalAssociationItem, toApp bundleId: String) -> Bool {
        AppLogger.shared.log("Updating default handler for '\(item.fileExtension)' to \(bundleId)...")
        
        let status = LSSetDefaultRoleHandlerForContentType(
            item.uti as CFString,
            .all,
            bundleId as CFString
        )
        
        let success = status == noErr
        if success {
            AppLogger.shared.log("Successfully updated global default handler for \(item.fileExtension).")
            // Refresh
            loadGlobalAssociations()
        } else {
            AppLogger.shared.log("Failed to update global association. Error status: \(status)")
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
