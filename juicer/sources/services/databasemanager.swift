import Foundation
import Combine

struct DatabaseDaemon: Identifiable {
    let id = UUID()
    let name: String
    let port: Int
    let isRunning: Bool
    let defaultPort: Int
    let iconName: String
}

struct LocalSQLiteFile: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let size: String
}

final class DatabaseManager: ObservableObject {
    static let shared = DatabaseManager()
    
    @Published var daemons: [DatabaseDaemon] = []
    @Published var sqliteFiles: [LocalSQLiteFile] = []
    @Published var isRefreshing = false
    @Published var activeCount = 0
    
    private init() {
        refreshAll()
    }
    
    func refreshAll() {
        isRefreshing = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let postgresOk = self.checkPort(5432)
            let mysqlOk = self.checkPort(3306)
            let redisOk = self.checkPort(6379)
            let mongoOk = self.checkPort(27017)
            
            let daemonList = [
                DatabaseDaemon(name: "PostgreSQL", port: 5432, isRunning: postgresOk, defaultPort: 5432, iconName: "cylinder.split.1x2.fill"),
                DatabaseDaemon(name: "MySQL / MariaDB", port: 3306, isRunning: mysqlOk, defaultPort: 3306, iconName: "externaldrive.fill"),
                DatabaseDaemon(name: "Redis Cache", port: 6379, isRunning: redisOk, defaultPort: 6379, iconName: "bolt.horizontal.fill"),
                DatabaseDaemon(name: "MongoDB", port: 27017, isRunning: mongoOk, defaultPort: 27017, iconName: "leaf.fill")
            ]
            
            let active = daemonList.filter { $0.isRunning }.count
            let foundSQLite = self.scanSQLiteFiles()
            
            DispatchQueue.main.async {
                self.daemons = daemonList
                self.activeCount = active
                self.sqliteFiles = foundSQLite
                self.isRefreshing = false
            }
        }
    }
    
    private func checkPort(_ port: Int) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/nc")
        process.arguments = ["-z", "-w", "1", "127.0.0.1", "\(port)"]
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    private func scanSQLiteFiles() -> [LocalSQLiteFile] {
        var results: [LocalSQLiteFile] = []
        let home = NSHomeDirectory()
        let locations = [
            home + "/Library/Application Support",
            home + "/Desktop/Projects"
        ]
        
        let fm = FileManager.default
        for folder in locations {
            if let enumerator = fm.enumerator(atPath: folder) {
                var count = 0
                while let file = enumerator.nextObject() as? String {
                    if file.hasSuffix(".sqlite") || file.hasSuffix(".sqlite3") || file.hasSuffix(".db") {
                        let fullPath = (folder as NSString).appendingPathComponent(file)
                        if let attrs = try? fm.attributesOfItem(atPath: fullPath),
                           let sizeBytes = attrs[.size] as? Int64 {
                            let sizeStr = ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
                            let name = (file as NSString).lastPathComponent
                            results.append(LocalSQLiteFile(name: name, path: fullPath, size: sizeStr))
                            count += 1
                            if count >= 15 { break }
                        }
                    }
                }
            }
        }
        return results
    }
}
