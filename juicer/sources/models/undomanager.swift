import Foundation
import AppKit

struct DeletionBackup: Identifiable, Codable {
    let id: UUID
    let name: String
    let originalPath: String
    let backupPath: String
    let sizeBytes: Int64
    let timestamp: Date
}

class DeletionUndoManager: ObservableObject {
    static let shared = DeletionUndoManager()
    
    @Published var backups: [DeletionBackup] = []
    
    private let fm = FileManager.default
    
    private var backupsDir: URL {
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fm.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)
        let path = appSupport.appendingPathComponent("Juicer/Backups", isDirectory: true)
        try? fm.createDirectory(at: path, withIntermediateDirectories: true)
        return path
    }
    
    private var metadataFile: URL {
        backupsDir.appendingPathComponent("backups_metadata.json")
    }
    
    private init() {
        loadBackups()
        pruneOldBackups()
    }
    
    func loadBackups() {
        guard let data = try? Data(contentsOf: metadataFile),
              let decoded = try? JSONDecoder().decode([DeletionBackup].self, from: data) else {
            DispatchQueue.main.async { self.backups = [] }
            return
        }
        DispatchQueue.main.async { self.backups = decoded }
    }
    
    func saveBackups() {
        if let data = try? JSONEncoder().encode(backups) {
            try? data.write(to: metadataFile)
        }
    }
    
    func trashItem(atPath path: String, completion: @escaping (Bool, String) -> Void) {
        let url = URL(fileURLWithPath: path)
        let name = url.lastPathComponent
        let timestamp = Date()
        let backupDest = backupsDir.appendingPathComponent("\(name)_\(Int(timestamp.timeIntervalSince1970))")
        
        var size: Int64 = 0
        var isDir: ObjCBool = false
        if fm.fileExists(atPath: path, isDirectory: &isDir) {
            if isDir.boolValue {
                size = directorySize(path: path)
            } else {
                size = (try? fm.attributesOfItem(atPath: path))?[.size] as? Int64 ?? 0
            }
        } else {
            completion(false, "File does not exist")
            return
        }
        
        do {
            try fm.moveItem(at: url, to: backupDest)
            let backup = DeletionBackup(
                id: UUID(),
                name: name,
                originalPath: path,
                backupPath: backupDest.path,
                sizeBytes: size,
                timestamp: timestamp
            )
            
            DispatchQueue.main.async {
                self.backups.append(backup)
                self.saveBackups()
                completion(true, "Successfully trashed to backup cabinet")
            }
        } catch {
            completion(false, error.localizedDescription)
        }
    }
    
    func restoreBackup(_ backup: DeletionBackup, completion: @escaping (Bool, String) -> Void) {
        let source = URL(fileURLWithPath: backup.backupPath)
        let dest = URL(fileURLWithPath: backup.originalPath)
        
        let parent = dest.deletingLastPathComponent()
        try? fm.createDirectory(at: parent, withIntermediateDirectories: true)
        
        do {
            if fm.fileExists(atPath: dest.path) {
                try fm.removeItem(at: dest)
            }
            try fm.moveItem(at: source, to: dest)
            
            DispatchQueue.main.async {
                if let idx = self.backups.firstIndex(where: { $0.id == backup.id }) {
                    self.backups.remove(at: idx)
                    self.saveBackups()
                }
                completion(true, "Successfully restored file/folder to original location")
            }
        } catch {
            completion(false, error.localizedDescription)
        }
    }
    
    func deleteBackupPermanently(_ backup: DeletionBackup) {
        let source = URL(fileURLWithPath: backup.backupPath)
        try? fm.removeItem(at: source)
        
        if let idx = backups.firstIndex(where: { $0.id == backup.id }) {
            backups.remove(at: idx)
            saveBackups()
        }
    }
    
    func pruneOldBackups() {
        let cutoff = Date().addingTimeInterval(-259200) // 3 days
        var updated: [DeletionBackup] = []
        for backup in backups {
            if backup.timestamp < cutoff {
                try? fm.removeItem(at: URL(fileURLWithPath: backup.backupPath))
            } else {
                updated.append(backup)
            }
        }
        self.backups = updated
        saveBackups()
    }
    
    private func directorySize(path: String) -> Int64 {
        var size: Int64 = 0
        guard let enumerator = fm.enumerator(at: URL(fileURLWithPath: path), includingPropertiesForKeys: [.fileSizeKey], options: []) else { return 0 }
        for case let url as URL in enumerator {
            if let fileSize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                size += Int64(fileSize)
            }
        }
        return size
    }
}
