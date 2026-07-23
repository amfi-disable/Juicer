import Foundation
import Combine

class WorkspaceDirectoryManager: ObservableObject {
    static let shared = WorkspaceDirectoryManager()
    
    @Published var currentDirectory: String = "" {
        didSet {
            let clean = currentDirectory.hasSuffix("/") && currentDirectory.count > 1 ? String(currentDirectory.dropLast()) : currentDirectory
            if clean != currentDirectory {
                DispatchQueue.main.async {
                    self.currentDirectory = clean
                }
                return
            }
            
            // Check if directory exists
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: clean, isDirectory: &isDir), isDir.boolValue {
                // If it changed, post a notification for interested views
                NotificationCenter.default.post(
                    name: Notification.Name("juicer.workspace.directoryChanged"),
                    object: nil,
                    userInfo: ["path": clean]
                )
            }
        }
    }
    
    private init() {
        let projectsPath = FileManager.default.homeDirectoryForCurrentUser.path + "/Desktop/Projects"
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: projectsPath, isDirectory: &isDir), isDir.boolValue {
            self.currentDirectory = projectsPath
        } else {
            self.currentDirectory = FileManager.default.homeDirectoryForCurrentUser.path
        }
    }
}
