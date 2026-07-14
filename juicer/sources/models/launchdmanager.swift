import Foundation
import AppKit

class LaunchdManager: ObservableObject {
    @Published var services: [LaunchdService] = []
    @Published var isLoading = false
    
    private let fileManager = FileManager.default
    
    func loadServices() {
        self.isLoading = true
        self.services = []
        
        AppLogger.shared.log("Enumerating launchd agents and daemons...")
        
        Task.detached(priority: .userInitiated) {
            let uid = getuid()
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            
            let directories: [(type: String, path: String)] = [
                ("User Agent", "\(home)/Library/LaunchAgents"),
                ("Global Agent", "/Library/LaunchAgents"),
                ("Global Daemon", "/Library/LaunchDaemons")
            ]
            
            var discovered: [LaunchdService] = []
            
            for dir in directories {
                guard let contents = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else {
                    continue
                }
                
                for item in contents where item.hasSuffix(".plist") {
                    let plistURL = URL(fileURLWithPath: dir.path).appendingPathComponent(item)
                    if let service = LaunchdService(plistURL: plistURL, type: dir.type) {
                        discovered.append(service)
                    }
                }
            }
            
            // Query running state via launchctl list
            let runningStates = self.getRunningStates()
            
            for i in 0..<discovered.count {
                let label = discovered[i].label
                if let state = runningStates[label] {
                    discovered[i].pid = state.pid
                    discovered[i].lastExitStatus = state.exitCode
                }
            }
            
            await MainActor.run {
                self.services = discovered.sorted(by: { $0.label < $1.label })
                self.isLoading = false
                AppLogger.shared.log("Loaded \(self.services.count) services.")
            }
        }
    }
    
    func toggleServiceState(_ service: LaunchdService, completion: @escaping (Bool) -> Void) {
        let isRunning = service.pid != nil
        let plistPath = service.plistURL.path
        
        AppLogger.shared.log("\(isRunning ? "Unloading" : "Loading") launchd task \(service.label)...")
        
        Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            
            // GUI uid for user agents or system for system daemons
            let uid = getuid()
            
            if isRunning {
                // Unload service
                process.arguments = ["unload", plistPath]
            } else {
                // Load service
                process.arguments = ["load", plistPath]
            }
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let success = process.terminationStatus == 0
                if success {
                    AppLogger.shared.log("Successfully \(isRunning ? "unloaded" : "loaded") \(service.label).")
                } else {
                    let errData = pipe.fileHandleForReading.readDataToEndOfFile()
                    let errStr = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown error"
                    AppLogger.shared.log("launchctl failed: \(errStr)")
                }
                
                // Reload list
                await MainActor.run {
                    self.loadServices()
                    completion(success)
                }
            } catch {
                AppLogger.shared.log("Error running launchctl: \(error.localizedDescription)")
                await MainActor.run {
                    completion(false)
                }
            }
        }
    }
    
    func saveService(_ service: LaunchdService, completion: @escaping (Bool) -> Void) {
        AppLogger.shared.log("Saving service plist \(service.label)...")
        
        Task.detached(priority: .userInitiated) {
            do {
                let dict = service.toDictionary()
                let plistData = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
                
                // Write to plist file
                try plistData.write(to: service.plistURL)
                AppLogger.shared.log("Saved \(service.filename) successfully.")
                
                await MainActor.run {
                    self.loadServices()
                    completion(true)
                }
            } catch {
                AppLogger.shared.log("Failed to save plist: \(error.localizedDescription)")
                await MainActor.run {
                    completion(false)
                }
            }
        }
    }
    
    func loadLogs(for service: LaunchdService) -> (stdout: String, stderr: String, unified: String) {
        var stdout = ""
        var stderr = ""
        var unified = ""
        
        if let outPath = service.standardOutPath {
            let expanded = NSString(string: outPath).expandingTildeInPath
            if let data = try? Data(contentsOf: URL(fileURLWithPath: expanded)),
               let text = String(data: data, encoding: .utf8) {
                stdout = text.components(separatedBy: "\n").suffix(200).joined(separator: "\n")
            } else {
                stdout = "Log file empty or not found: \(expanded)"
            }
        }
        
        if let errPath = service.standardErrorPath {
            let expanded = NSString(string: errPath).expandingTildeInPath
            if let data = try? Data(contentsOf: URL(fileURLWithPath: expanded)),
               let text = String(data: data, encoding: .utf8) {
                stderr = text.components(separatedBy: "\n").suffix(200).joined(separator: "\n")
            } else {
                stderr = "Log file empty or not found: \(expanded)"
            }
        }
        
        if stdout.isEmpty && stderr.isEmpty {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/log")
            let predicate = "eventMessage CONTAINS \"\(service.label)\""
            process.arguments = ["show", "--last", "1h", "--style", "compact", "--predicate", predicate]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe()
            
            do {
                try process.run()
                process.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let text = String(data: data, encoding: .utf8), !text.isEmpty {
                    unified = text.components(separatedBy: "\n").suffix(200).joined(separator: "\n")
                } else {
                    unified = "No system log messages recorded for \(service.label) in the last hour."
                }
            } catch {
                unified = "Failed to query system log: \(error.localizedDescription)"
            }
        }
        
        return (stdout, stderr, unified)
    }
    
    func deleteService(_ service: LaunchdService, completion: @escaping (Bool) -> Void) {
        AppLogger.shared.log("Trashing plist file for \(service.label)...")
        
        // Unload first
        toggleServiceState(service) { [weak self] _ in
            Task.detached(priority: .userInitiated) {
                do {
                    if FileManager.default.fileExists(atPath: service.plistURL.path) {
                        try FileManager.default.trashItem(at: service.plistURL, resultingItemURL: nil)
                    }
                    
                    await MainActor.run {
                        self?.loadServices()
                        completion(true)
                    }
                } catch {
                    AppLogger.shared.log("Failed to trash plist: \(error.localizedDescription)")
                    await MainActor.run {
                        completion(false)
                    }
                }
            }
        }
    }
    
    private func getRunningStates() -> [String: (pid: Int?, exitCode: Int?)] {
        var states: [String: (pid: Int?, exitCode: Int?)] = [:]
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["list"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: "\n")
                
                // Header format: PID  Status  Label
                for line in lines.dropFirst() {
                    let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    guard parts.count >= 3 else { continue }
                    
                    let pidStr = parts[0]
                    let statusStr = parts[1]
                    let label = parts[2]
                    
                    let pid = Int(pidStr)
                    let exitCode = Int(statusStr)
                    
                    states[label] = (pid: pid, exitCode: exitCode)
                }
            }
        } catch {
            AppLogger.shared.log("Failed to list active processes: \(error.localizedDescription)")
        }
        
        return states
    }
}
