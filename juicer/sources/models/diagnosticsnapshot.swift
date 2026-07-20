import Foundation

struct SnapshotDiff: Identifiable {
    let id = UUID()
    let category: String // "Hosts Mappings", "DNS Configuration", "Launch Services", "Homebrew Packages"
    let action: String   // "Added", "Removed", "Modified"
    let detail: String
}

struct DiagnosticSnapshot: Identifiable, Codable {
    var id = UUID()
    let timestamp: Date
    let dnsServers: [String]
    let hostsLines: [String]
    let launchDaemons: [String]
    let installedCasks: [String]
    
    // MARK: - Capture current system state
    
    static func captureCurrentState() -> DiagnosticSnapshot {
        let timestamp = Date()
        
        // DNS Servers
        var dns: [String] = []
        if let contents = try? String(contentsOfFile: "/etc/resolv.conf", encoding: .utf8) {
            dns = contents.components(separatedBy: .newlines)
                .filter { $0.hasPrefix("nameserver") }
                .map { $0.replacingOccurrences(of: "nameserver ", with: "").trimmingCharacters(in: .whitespaces) }
        }
        
        // Hosts
        var hosts: [String] = []
        if let contents = try? String(contentsOfFile: "/etc/hosts", encoding: .utf8) {
            hosts = contents.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && !$0.hasPrefix("#") }
        }
        
        // Launch Daemons & Agents
        var launchd: [String] = []
        let fm = FileManager.default
        let launchdPaths = [
            "/Library/LaunchDaemons",
            "/Library/LaunchAgents",
            NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first.map { "\($0)/LaunchAgents" }
        ].compactMap { $0 }
        
        for path in launchdPaths {
            if let contents = try? fm.contentsOfDirectory(atPath: path) {
                launchd.append(contentsOf: contents.filter { $0.hasSuffix(".plist") })
            }
        }
        
        // Homebrew Casks
        var casks: [String] = []
        if fm.fileExists(atPath: "/opt/homebrew/Caskroom") {
            if let contents = try? fm.contentsOfDirectory(atPath: "/opt/homebrew/Caskroom") {
                casks = contents
            }
        }
        
        return DiagnosticSnapshot(
            timestamp: timestamp,
            dnsServers: dns,
            hostsLines: hosts,
            launchDaemons: launchd,
            installedCasks: casks
        )
    }
    
    // MARK: - Storage Helper
    
    private static var snapshotsDir: URL {
        let fm = FileManager.default
        let supportDir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fm.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)
        let dir = supportDir.appendingPathComponent("com.even.juicer/snapshots")
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    func save() {
        let file = DiagnosticSnapshot.snapshotsDir.appendingPathComponent("\(Int(timestamp.timeIntervalSince1970)).json")
        if let data = try? JSONEncoder().encode(self) {
            try? data.write(to: file)
        }
    }
    
    static func loadAll() -> [DiagnosticSnapshot] {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(atPath: snapshotsDir.path) else {
            return []
        }
        
        var snapshots: [DiagnosticSnapshot] = []
        for file in contents {
            if file.hasSuffix(".json") {
                let fileURL = snapshotsDir.appendingPathComponent(file)
                if let data = try? Data(contentsOf: fileURL),
                   let snapshot = try? JSONDecoder().decode(DiagnosticSnapshot.self, from: data) {
                    snapshots.append(snapshot)
                }
            }
        }
        return snapshots.sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    static func delete(_ snapshot: DiagnosticSnapshot) {
        let file = snapshotsDir.appendingPathComponent("\(Int(snapshot.timestamp.timeIntervalSince1970)).json")
        try? FileManager.default.removeItem(at: file)
    }
    
    // MARK: - Diffing Engine
    
    func diff(against older: DiagnosticSnapshot) -> [SnapshotDiff] {
        var diffs: [SnapshotDiff] = []
        
        // 1. DNS Diff
        let addedDNS = Set(self.dnsServers).subtracting(older.dnsServers)
        let removedDNS = Set(older.dnsServers).subtracting(self.dnsServers)
        for dns in addedDNS { diffs.append(SnapshotDiff(category: "DNS Server", action: "Added", detail: dns)) }
        for dns in removedDNS { diffs.append(SnapshotDiff(category: "DNS Server", action: "Removed", detail: dns)) }
        
        // 2. Hosts Diff
        let addedHosts = Set(self.hostsLines).subtracting(older.hostsLines)
        let removedHosts = Set(older.hostsLines).subtracting(self.hostsLines)
        for line in addedHosts { diffs.append(SnapshotDiff(category: "Hosts Rule", action: "Added", detail: line)) }
        for line in removedHosts { diffs.append(SnapshotDiff(category: "Hosts Rule", action: "Removed", detail: line)) }
        
        // 3. LaunchDaemons Diff
        let addedLaunchd = Set(self.launchDaemons).subtracting(older.launchDaemons)
        let removedLaunchd = Set(older.launchDaemons).subtracting(self.launchDaemons)
        for item in addedLaunchd { diffs.append(SnapshotDiff(category: "Launch Daemon", action: "Added", detail: item)) }
        for item in removedLaunchd { diffs.append(SnapshotDiff(category: "Launch Daemon", action: "Removed", detail: item)) }
        
        // 4. Casks Diff
        let addedCasks = Set(self.installedCasks).subtracting(older.installedCasks)
        let removedCasks = Set(older.installedCasks).subtracting(self.installedCasks)
        for cask in addedCasks { diffs.append(SnapshotDiff(category: "Homebrew Cask", action: "Added", detail: cask)) }
        for cask in removedCasks { diffs.append(SnapshotDiff(category: "Homebrew Cask", action: "Removed", detail: cask)) }
        
        return diffs
    }
}
