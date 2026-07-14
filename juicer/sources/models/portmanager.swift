import Foundation

struct ActivePort: Identifiable, Hashable, Codable {
    var id: String { "\(port)-\(pid)" }
    let port: Int
    let protocolName: String // "TCP" or "UDP"
    let processName: String
    let pid: Int
    var commandLineArgs: String = ""
    var parentPid: Int? = nil
}

class PortManager: ObservableObject {
    @Published var activePorts: [ActivePort] = []
    @Published var isLoading = false
    
    // Default development ports filter
    static let devPorts: Set<Int> = [80, 443, 3000, 3001, 4000, 5000, 5001, 8000, 8080, 9000, 9090, 8081]
    
    func loadPorts() {
        self.isLoading = true
        self.activePorts = []
        
        Task.detached(priority: .userInitiated) {
            var portsList: [ActivePort] = []
            
            // Run lsof -nP -i -sTCP:LISTEN (gets both IPv4/IPv6 listening TCP sockets)
            let lsofOutput = Self.runShellCommand("/usr/sbin/lsof -nP -iTCP -sTCP:LISTEN")
            let lines = lsofOutput.components(separatedBy: "\n")
            
            // Expected format: COMMAND   PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
            for line in lines.dropFirst() {
                let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                guard parts.count >= 8 else { continue }
                
                let processName = parts[0]
                guard let pid = Int(parts[1]) else { continue }
                let nodeName = parts[8] // e.g. "*:3000" or "127.0.0.1:8080"
                
                // Extract port number
                if let colonIndex = nodeName.lastIndex(of: ":") {
                    let portStr = String(nodeName[nodeName.index(after: colonIndex)...])
                    if let portNumber = Int(portStr.trimmingCharacters(in: .whitespacesAndNewlines)) {
                        
                        // Query command line args and parent PID
                        let args = Self.runShellCommand("/bin/ps -p \(pid) -o args=").trimmingCharacters(in: .whitespacesAndNewlines)
                        let ppidStr = Self.runShellCommand("/bin/ps -p \(pid) -o ppid=").trimmingCharacters(in: .whitespacesAndNewlines)
                        let ppid = Int(ppidStr)
                        
                        let activePort = ActivePort(
                            port: portNumber,
                            protocolName: "TCP",
                            processName: processName,
                            pid: pid,
                            commandLineArgs: args.isEmpty ? "No arguments" : args,
                            parentPid: ppid
                        )
                        portsList.append(activePort)
                    }
                }
            }
            
            // Deduplicate ports
            var uniquePorts: [ActivePort] = []
            for item in portsList {
                if !uniquePorts.contains(where: { $0.port == item.port && $0.pid == item.pid }) {
                    uniquePorts.append(item)
                }
            }
            
            let sorted = uniquePorts.sorted(by: { $0.port < $1.port })
            
            await MainActor.run {
                self.activePorts = sorted
                self.isLoading = false
                AppLogger.shared.log("Loaded \(self.activePorts.count) active listening ports.")
            }
        }
    }
    
    func killProcess(pid: Int, completion: @escaping (Bool) -> Void) {
        // Read kill preference setting
        let forceKill = UserDefaults.standard.bool(forKey: "juicer.settings.killForceful")
        let signal = forceKill ? "-9" : "-15"
        
        AppLogger.shared.log("Sending signal \(signal) to process PID \(pid)...")
        
        Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/kill")
            process.arguments = [signal, String(pid)]
            
            do {
                try process.run()
                process.waitUntilExit()
                let success = process.terminationStatus == 0
                await MainActor.run {
                    self.loadPorts()
                    completion(success)
                }
            } catch {
                AppLogger.shared.log("Failed to kill process PID \(pid): \(error.localizedDescription)")
                await MainActor.run {
                    completion(false)
                }
            }
        }
    }
    
    private static func runShellCommand(_ command: String) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        try? process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
