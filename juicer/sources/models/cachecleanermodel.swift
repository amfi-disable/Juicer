import Foundation
import AppKit

// MARK: - Insight Category

struct InsightItem: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let description: String
    let category: InsightCategory
    var sizeBytes: Int64 = -1
    var isSelected: Bool = false
    var exists: Bool = false

    enum InsightCategory: String, CaseIterable {
        case system = "System"
        case media = "Media & Apps"
        case developer = "Developer"
        case deps = "Dependencies"
        case ide = "IDE & Editors"

        var icon: String {
            switch self {
            case .system: return "gearshape.fill"
            case .media: return "play.circle.fill"
            case .developer: return "hammer.fill"
            case .deps: return "shippingbox.fill"
            case .ide: return "curlybraces.square.fill"
            }
        }
    }
}

struct ProjectCleanEntry: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let dirType: String        // "node_modules", ".build", "target", etc.
    var sizeBytes: Int64
    var isSelected: Bool = true
}

// MARK: - Manager

struct RollbackBackup: Identifiable, Codable {
    let id: UUID
    let name: String
    let originalPath: String
    let backupPath: String
    let timestamp: Date
    let sizeBytes: Int64
}

class CacheCleanerManager: ObservableObject {
    @Published var insights: [InsightItem] = []
    @Published var projectEntries: [ProjectCleanEntry] = []
    @Published var backups: [RollbackBackup] = []
    @Published var isScanning: Bool = false
    @Published var isCleaning: Bool = false
    @Published var totalCleanableBytes: Int64 = 0
    @Published var projectScanRoot: String = ""
    @Published var log: [String] = []

    private let fm = FileManager.default

    private var backupsDir: URL {
        let caches = fm.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let dir = caches.appendingPathComponent("com.even.juicer/backups")
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private var backupsMetadataFile: URL {
        backupsDir.appendingPathComponent("metadata.json")
    }

    // MARK: - Build Insight List

    func buildInsights() {
        let home = fm.homeDirectoryForCurrentUser.path

        var items: [InsightItem] = [
            // System
            InsightItem(name: "System Logs",
                        path: "\(home)/Library/Logs",
                        description: "Application crash reports and diagnostic log archives.",
                        category: .system),
            InsightItem(name: "Diagnostic Reports",
                        path: "\(home)/Library/Logs/DiagnosticReports",
                        description: "macOS crash and hang reports for installed applications.",
                        category: .system),
            InsightItem(name: "Saved Application State",
                        path: "\(home)/Library/Saved Application State",
                        description: "Window restoration state data saved when apps quit.",
                        category: .system),
            InsightItem(name: "Trash",
                        path: "\(home)/.Trash",
                        description: "Files awaiting permanent deletion in the Trash.",
                        category: .system),
            InsightItem(name: "Old Downloads (90d+)",
                        path: "\(home)/Downloads",
                        description: "Files in Downloads not modified in the last 90 days.",
                        category: .system),
            // Media & Apps
            InsightItem(name: "iOS Backups",
                        path: "\(home)/Library/Application Support/MobileSync/Backup",
                        description: "Full device backups created by Finder / iTunes.",
                        category: .media),
            InsightItem(name: "Spotify Cache",
                        path: "\(home)/Library/Application Support/Spotify/PersistentCache",
                        description: "Spotify audio stream and thumbnail persistent cache.",
                        category: .media),
            InsightItem(name: "Slack Logs",
                        path: "\(home)/Library/Application Support/Slack/logs",
                        description: "Slack desktop client crash and diagnostic logs.",
                        category: .media),
            InsightItem(name: "Chrome Cache",
                        path: "\(home)/Library/Caches/Google/Chrome/Default/Cache",
                        description: "Google Chrome browser HTTP cache and offline resources.",
                        category: .media),
            InsightItem(name: "Firefox Cache",
                        path: "\(home)/Library/Caches/Firefox/Profiles",
                        description: "Mozilla Firefox browser cache and offline data.",
                        category: .media),
            InsightItem(name: "Safari Cache",
                        path: "\(home)/Library/Caches/com.apple.Safari",
                        description: "Apple Safari browser cache files.",
                        category: .media),
            InsightItem(name: "Mail Downloads",
                        path: "\(home)/Library/Mail Downloads",
                        description: "Email attachments opened from Apple Mail.",
                        category: .media),
            InsightItem(name: "Photos Library Originals Backup",
                        path: "\(home)/Pictures/Photos Library.photoslibrary/Masters",
                        description: "Original unprocessed photos stored in the Photos library.",
                        category: .media),
            // Developer
            InsightItem(name: "Xcode DerivedData",
                        path: "\(home)/Library/Developer/Xcode/DerivedData",
                        description: "Xcode compiled build artifacts, indexes, and logs.",
                        category: .developer),
            InsightItem(name: "Xcode Simulators",
                        path: "\(home)/Library/Developer/CoreSimulator/Devices",
                        description: "iOS/watchOS/tvOS simulator device data and runtimes.",
                        category: .developer),
            InsightItem(name: "Xcode Archives",
                        path: "\(home)/Library/Developer/Xcode/Archives",
                        description: "Xcode .xcarchive bundles created for App Store distribution.",
                        category: .developer),
            InsightItem(name: "Docker Data",
                        path: "\(home)/Library/Containers/com.docker.docker/Data",
                        description: "Docker Desktop container images, volumes, and metadata.",
                        category: .developer),
            InsightItem(name: "Homebrew Caches",
                        path: "\(home)/Library/Caches/Homebrew",
                        description: "Homebrew downloaded formula and cask archives.",
                        category: .developer),
            // Dependencies
            InsightItem(name: "pip Cache",
                        path: "\(home)/Library/Caches/pip",
                        description: "Python pip package download cache.",
                        category: .deps),
            InsightItem(name: "Gradle Caches",
                        path: "\(home)/.gradle/caches",
                        description: "Gradle build system cached artifacts and wrapper JARs.",
                        category: .deps),
            InsightItem(name: "Maven Repository",
                        path: "\(home)/.m2/repository",
                        description: "Maven local artifact repository (JARs, POMs).",
                        category: .deps),
            InsightItem(name: "CocoaPods Cache",
                        path: "\(home)/Library/Caches/CocoaPods",
                        description: "CocoaPods pod download cache.",
                        category: .deps),
            InsightItem(name: "Cargo Registry",
                        path: "\(home)/.cargo/registry",
                        description: "Rust Cargo crate source archives.",
                        category: .deps),
            InsightItem(name: "npm Cache",
                        path: "\(home)/.npm/_cacache",
                        description: "npm package manager cache directory.",
                        category: .deps),
            // IDE & Editors
            InsightItem(name: "JetBrains Cache",
                        path: "\(home)/Library/Caches/JetBrains",
                        description: "IntelliJ, WebStorm, PyCharm IDE system caches.",
                        category: .ide),
            InsightItem(name: "VS Code Cache",
                        path: "\(home)/Library/Application Support/Code/Cache",
                        description: "VS Code Electron renderer cache data.",
                        category: .ide),
            InsightItem(name: "Android Studio Cache",
                        path: "\(home)/Library/Caches/Google/AndroidStudio",
                        description: "Android Studio IDE caches and indices.",
                        category: .ide),
        ]

        // Mark existing ones
        for i in items.indices {
            let exists = fm.fileExists(atPath: items[i].path)
            items[i].exists = exists
        }

        self.insights = items
    }

    // MARK: - Scan Sizes

    func scanSizes() {
        isScanning = true
        buildInsights()

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            var updated = self.insights

            for i in updated.indices {
                guard updated[i].exists else { continue }
                let size: Int64
                // Old downloads: measure only files > 90 days
                if updated[i].name.hasPrefix("Old Downloads") {
                    size = self.measureOldDownloads(path: updated[i].path, daysOld: 90)
                } else {
                    size = self.directorySize(path: updated[i].path)
                }
                updated[i].sizeBytes = size
            }

            let total = updated.filter { $0.exists && $0.sizeBytes > 0 }.reduce(0) { $0 + $1.sizeBytes }

            await MainActor.run {
                self.insights = updated.sorted {
                    ($0.sizeBytes > 0 ? $0.sizeBytes : -1) > ($1.sizeBytes > 0 ? $1.sizeBytes : -1)
                }
                self.totalCleanableBytes = total
                self.isScanning = false
            }
        }
    }

    // MARK: - Project Dependency Cleaner

    static let cleanableDirNames: Set<String> = [
        // JS/Node
        "node_modules", ".yarn", ".pnpm-store", ".next", ".nuxt", ".turbo",
        ".parcel-cache", ".vite", ".nx", "bower_components", ".bun", ".deno",
        // Python
        "__pycache__", ".pytest_cache", ".mypy_cache", ".ruff_cache",
        "venv", ".venv", "virtualenv", ".tox", ".eggs", ".ipynb_checkpoints",
        // Build outputs
        "build", "dist", "target", ".output", "coverage", ".nyc_output",
        ".angular", ".svelte-kit", ".astro", ".docusaurus",
        // Apple dev
        "DerivedData", "Pods", ".build", "Carthage", "xcuserdata",
        // Java/Gradle
        ".gradle", ".m2", "out",
        // Misc
        ".terraform", ".vagrant", "tmp", "temp", ".cache",
        // Ruby
        "vendor", ".bundle",
        // Go
        "pkg",
    ]

    func scanProjectDeps(root: String) {
        let searchRoot = root.isEmpty ? fm.homeDirectoryForCurrentUser.path : root
        projectScanRoot = searchRoot
        isScanning = true
        projectEntries = []

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            var found: [ProjectCleanEntry] = []
            self.walkForCleanable(dir: searchRoot, depth: 0, maxDepth: 6, found: &found)
            let sorted = found.sorted { $0.sizeBytes > $1.sizeBytes }

            await MainActor.run {
                self.projectEntries = sorted
                self.isScanning = false
            }
        }
    }

    private func walkForCleanable(dir: String, depth: Int, maxDepth: Int, found: inout [ProjectCleanEntry]) {
        guard depth <= maxDepth else { return }
        guard let contents = try? fm.contentsOfDirectory(atPath: dir) else { return }

        for item in contents {
            if item.hasPrefix(".") && !CacheCleanerManager.cleanableDirNames.contains(item) { continue }
            let fullPath = (dir as NSString).appendingPathComponent(item)

            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: fullPath, isDirectory: &isDir), isDir.boolValue else { continue }

            if CacheCleanerManager.cleanableDirNames.contains(item) {
                let size = directorySize(path: fullPath)
                if size > 0 {
                    found.append(ProjectCleanEntry(
                        name: item, path: fullPath, dirType: item,
                        sizeBytes: size, isSelected: true
                    ))
                }
            } else {
                // Don't recurse into known skip dirs
                let skipTop = ["System", "Library", ".git", ".hg", ".svn", "Applications"]
                if !skipTop.contains(item) {
                    walkForCleanable(dir: fullPath, depth: depth + 1, maxDepth: maxDepth, found: &found)
                }
            }
        }
    }

    // MARK: - Backups Persistence & Management

    func loadBackups() {
        if let data = try? Data(contentsOf: backupsMetadataFile),
           let decoded = try? JSONDecoder().decode([RollbackBackup].self, from: data) {
            self.backups = decoded
        } else {
            self.backups = []
        }
    }

    func saveBackups() {
        if let data = try? JSONEncoder().encode(backups) {
            try? data.write(to: backupsMetadataFile)
        }
    }

    func pruneOldBackups() {
        loadBackups()
        let cutoff = Date().addingTimeInterval(-259200) // 3 days (3 * 86400)
        var updated: [RollbackBackup] = []
        
        for backup in backups {
            if backup.timestamp < cutoff {
                AppLogger.shared.log("Pruning expired cache backup: \(backup.name)")
                try? fm.removeItem(at: URL(fileURLWithPath: backup.backupPath))
            } else {
                updated.append(backup)
            }
        }
        self.backups = updated
        saveBackups()
    }

    func restoreBackup(_ backup: RollbackBackup) {
        let sourceURL = URL(fileURLWithPath: backup.backupPath)
        let destURL = URL(fileURLWithPath: backup.originalPath)
        
        // Ensure parent directory exists
        let parentDir = destURL.deletingLastPathComponent()
        try? fm.createDirectory(at: parentDir, withIntermediateDirectories: true)
        
        do {
            if fm.fileExists(atPath: destURL.path) {
                try fm.removeItem(at: destURL)
            }
            try fm.moveItem(at: sourceURL, to: destURL)
            
            // Remove from metadata list
            if let idx = backups.firstIndex(where: { $0.id == backup.id }) {
                backups.remove(at: idx)
                saveBackups()
            }
            log.append("✅ Restored: \(backup.name) to \(backup.originalPath)")
        } catch {
            log.append("❌ Failed to restore \(backup.name): \(error.localizedDescription)")
        }
    }

    // MARK: - Trash Selected Insights (With Rollback Backup support)

    func trashSelected(completion: @escaping (Int, Int64) -> Void) {
        isCleaning = true
        let toClean = insights.filter { $0.isSelected && $0.exists }
        let timestamp = Date()

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            var cleaned = 0
            var freed: Int64 = 0
            var newBackups: [RollbackBackup] = []

            // Reload backups metadata first
            await MainActor.run {
                self.loadBackups()
            }

            for item in toClean {
                let url = URL(fileURLWithPath: item.path)
                let backupDestURL = self.backupsDir.appendingPathComponent("\(item.name)_\(Int(timestamp.timeIntervalSince1970))")
                
                var backedUp = false
                do {
                    // Try to move folder/file to backup dir
                    if self.fm.fileExists(atPath: url.path) {
                        try self.fm.moveItem(at: url, to: backupDestURL)
                        backedUp = true
                        
                        let backupObj = RollbackBackup(
                            id: UUID(),
                            name: item.name,
                            originalPath: item.path,
                            backupPath: backupDestURL.path,
                            timestamp: timestamp,
                            sizeBytes: item.sizeBytes
                        )
                        newBackups.append(backupObj)
                        
                        cleaned += 1
                        freed += max(0, item.sizeBytes)
                        await MainActor.run {
                            self.log.append("📦 Cleaned & Backed up: \(item.name)")
                        }
                    }
                } catch {
                    // Fallback to standard trash if move fails (e.g. across mount volumes)
                    do {
                        if self.fm.fileExists(atPath: url.path) {
                            try self.fm.trashItem(at: url, resultingItemURL: nil)
                            cleaned += 1
                            freed += max(0, item.sizeBytes)
                            await MainActor.run {
                                self.log.append("🗑 Trashed (No Backup): \(item.name)")
                            }
                        }
                    } catch {
                        await MainActor.run {
                            self.log.append("❌ Failed: \(item.name) — \(error.localizedDescription)")
                        }
                    }
                }
            }

            await MainActor.run {
                if !newBackups.isEmpty {
                    self.backups.append(contentsOf: newBackups)
                    self.saveBackups()
                }
                self.isCleaning = false
                completion(cleaned, freed)
            }
        }
    }

    // MARK: - Trash Project Deps

    func trashProjectDeps(completion: @escaping (Int, Int64) -> Void) {
        isCleaning = true
        let selected = projectEntries.filter { $0.isSelected }

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            var cleaned = 0; var freed: Int64 = 0

            for entry in selected {
                let url = URL(fileURLWithPath: entry.path)
                do {
                    try self.fm.trashItem(at: url, resultingItemURL: nil)
                    cleaned += 1; freed += max(0, entry.sizeBytes)
                    await MainActor.run { self.log.append("🗑 Cleaned: \(entry.name) at \(entry.path)") }
                } catch {
                    await MainActor.run { self.log.append("❌ Failed: \(entry.name) — \(error.localizedDescription)") }
                }
            }

            await MainActor.run {
                self.projectEntries.removeAll { $0.isSelected }
                self.isCleaning = false
                completion(cleaned, freed)
            }
        }
    }

    // MARK: - Helpers

    private func directorySize(path: String) -> Int64 {
        var size: Int64 = 0
        guard let enumerator = fm.enumerator(at: URL(fileURLWithPath: path),
                                              includingPropertiesForKeys: [.fileSizeKey],
                                              options: [.skipsHiddenFiles]) else { return 0 }
        for case let url as URL in enumerator {
            if let fileSize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                size += Int64(fileSize)
            }
        }
        return size
    }

    private func measureOldDownloads(path: String, daysOld: Int) -> Int64 {
        guard let contents = try? fm.contentsOfDirectory(atPath: path) else { return 0 }
        let cutoff = Date().addingTimeInterval(-Double(daysOld * 86400))
        var total: Int64 = 0
        for item in contents {
            if item.hasPrefix(".") { continue }
            let fullPath = (path as NSString).appendingPathComponent(item)
            if let attrs = try? fm.attributesOfItem(atPath: fullPath),
               let modified = attrs[.modificationDate] as? Date,
               modified < cutoff {
                if let size = attrs[.size] as? Int64 {
                    total += size
                }
            }
        }
        return total
    }

    static func formatBytes(_ bytes: Int64) -> String {
        guard bytes >= 0 else { return "—" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
