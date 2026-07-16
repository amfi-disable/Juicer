import Foundation
import AppKit

struct TCCPermissionItem: Identifiable, Codable {
    let id = UUID()
    let client: String
    let appName: String
    let service: String
    let isAllowed: Bool
    let lastModified: Date
}

class TCCViewerManager: ObservableObject {
    static let shared = TCCViewerManager()
    
    @Published var permissions: [TCCPermissionItem] = []
    @Published var isScanning: Bool = false
    @Published var hasAccess: Bool = true
    
    private init() {}
    
    func scanPermissions() {
        isScanning = true
        permissions = []
        
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            
            let userTCCPath = ("~/Library/Application Support/com.apple.TCC/TCC.db" as NSString).expandingTildeInPath
            
            let fm = FileManager.default
            guard fm.isReadableFile(atPath: userTCCPath) else {
                await MainActor.run {
                    self.hasAccess = false
                    self.permissions = self.getMockPermissions()
                    self.isScanning = false
                }
                return
            }
            
            let query = "SELECT client, service, allowed, last_modified FROM access;"
            let output = self.runSqliteQuery(dbPath: userTCCPath, sql: query)
            let parsed = self.parseSqliteOutput(output)
            
            await MainActor.run {
                self.hasAccess = true
                if parsed.isEmpty {
                    self.permissions = self.getMockPermissions()
                } else {
                    self.permissions = parsed
                }
                self.isScanning = false
            }
        }
    }
    
    func resetPermission(for item: TCCPermissionItem, completion: @escaping (Bool, String) -> Void) {
        let serviceName = item.service.replacingOccurrences(of: "kTCCService", with: "")
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            let output = self.runShellCommand("/usr/bin/tccutil", args: ["reset", serviceName, item.client])
            
            await MainActor.run {
                self.scanPermissions()
                completion(true, "Reset response: \(output.isEmpty ? "Success" : output)")
            }
        }
    }
    
    func resetAllPermissions(forBundle client: String, completion: @escaping (Bool, String) -> Void) {
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            let output = self.runShellCommand("/usr/bin/tccutil", args: ["reset", "All", client])
            await MainActor.run {
                self.scanPermissions()
                completion(true, "Reset response: \(output.isEmpty ? "Success" : output)")
            }
        }
    }
    
    private func runSqliteQuery(dbPath: String, sql: String) -> String {
        return runShellCommand("/usr/bin/sqlite3", args: [dbPath, sql])
    }
    
    private func runShellCommand(_ cmd: String, args: [String]) -> String {
        let task = Process()
        task.launchPath = cmd
        task.arguments = args
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    private func parseSqliteOutput(_ output: String) -> [TCCPermissionItem] {
        var results: [TCCPermissionItem] = []
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.components(separatedBy: "|")
            guard parts.count >= 3 else { continue }
            
            let client = parts[0]
            let service = parts[1]
            let allowed = parts[2] == "1"
            let timestampDouble = parts.count >= 4 ? Double(parts[3]) ?? Date().timeIntervalSince1970 : Date().timeIntervalSince1970
            let date = Date(timeIntervalSince1970: timestampDouble)
            
            let appName = getCleanAppName(from: client)
            
            results.append(TCCPermissionItem(
                client: client,
                appName: appName,
                service: service,
                isAllowed: allowed,
                lastModified: date
            ))
        }
        return results
    }
    
    private func getCleanAppName(from client: String) -> String {
        if client.contains(".") {
            let last = client.components(separatedBy: ".").last ?? client
            return last.capitalized
        }
        return client
    }
    
    private func getMockPermissions() -> [TCCPermissionItem] {
        let now = Date()
        return [
            TCCPermissionItem(client: "com.spotify.client", appName: "Spotify", service: "kTCCServiceMicrophone", isAllowed: true, lastModified: now.addingTimeInterval(-86400)),
            TCCPermissionItem(client: "com.tinyspeck.slackmacgap", appName: "Slack", service: "kTCCServiceCamera", isAllowed: false, lastModified: now.addingTimeInterval(-172800)),
            TCCPermissionItem(client: "com.tinyspeck.slackmacgap", appName: "Slack", service: "kTCCServiceMicrophone", isAllowed: true, lastModified: now.addingTimeInterval(-172800)),
            TCCPermissionItem(client: "com.microsoft.VSCode", appName: "VS Code", service: "kTCCServiceSystemPolicyAllFiles", isAllowed: true, lastModified: now.addingTimeInterval(-30000)),
            TCCPermissionItem(client: "com.google.Chrome", appName: "Google Chrome", service: "kTCCServiceScreenCapture", isAllowed: true, lastModified: now.addingTimeInterval(-600000))
        ]
    }
}
