import Foundation
import Combine

struct DockerContainer: Identifiable, Hashable {
    let id: String
    let name: String
    let image: String
    let status: String
    let state: String
    let created: String
    let ports: String
    
    var isRunning: Bool {
        state.lowercased() == "running" || status.lowercased().contains("up")
    }
}

struct DockerDiskUsage: Identifiable {
    let id = UUID()
    let type: String
    let totalCount: Int
    let activeCount: Int
    let size: String
    let reclaimable: String
}

final class DockerManager: ObservableObject {
    static let shared = DockerManager()
    
    @Published var isDockerInstalled = false
    @Published var isDaemonRunning = false
    @Published var dockerPath: String = ""
    @Published var containers: [DockerContainer] = []
    @Published var diskUsage: [DockerDiskUsage] = []
    @Published var isRefreshing = false
    @Published var statusMessage: String = ""
    @Published var totalReclaimableSpace: String = "0 B"
    
    private init() {
        detectDocker()
    }
    
    func detectDocker() {
        let candidates = [
            "/opt/homebrew/bin/docker",
            "/usr/local/bin/docker",
            NSHomeDirectory() + "/.orbstack/bin/docker",
            NSHomeDirectory() + "/.colima/bin/docker",
            "/usr/bin/docker"
        ]
        
        for path in candidates {
            if FileManager.default.fileExists(atPath: path) {
                self.dockerPath = path
                self.isDockerInstalled = true
                break
            }
        }
        
        if !isDockerInstalled {
            // Check PATH fallback
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
            process.arguments = ["docker"]
            let pipe = Pipe()
            process.standardOutput = pipe
            try? process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !output.isEmpty {
                self.dockerPath = output
                self.isDockerInstalled = true
            }
        }
        
        refreshAll()
    }
    
    func refreshAll() {
        guard isDockerInstalled else { return }
        isRefreshing = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let daemonOk = self.checkDaemonStatus()
            let loadedContainers = daemonOk ? self.loadContainers() : []
            let loadedDiskUsage = daemonOk ? self.loadDiskUsage() : []
            
            DispatchQueue.main.async {
                self.isDaemonRunning = daemonOk
                self.containers = loadedContainers
                self.diskUsage = loadedDiskUsage
                self.isRefreshing = false
            }
        }
    }
    
    private func checkDaemonStatus() -> Bool {
        guard !dockerPath.isEmpty else { return false }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: dockerPath)
        process.arguments = ["info"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    private func loadContainers() -> [DockerContainer] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: dockerPath)
        process.arguments = ["ps", "-a", "--format", "{{.ID}}||{{.Names}}||{{.Image}}||{{.Status}}||{{.State}}||{{.CreatedAt}}||{{.Ports}}"]
        let pipe = Pipe()
        process.standardOutput = pipe
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return [] }
            
            var items: [DockerContainer] = []
            let lines = output.components(separatedBy: .newlines)
            for line in lines where !line.trimmingCharacters(in: .whitespaces).isEmpty {
                let parts = line.components(separatedBy: "||")
                if parts.count >= 5 {
                    let container = DockerContainer(
                        id: parts[0],
                        name: parts[1],
                        image: parts[2],
                        status: parts[3],
                        state: parts[4],
                        created: parts.count > 5 ? parts[5] : "",
                        ports: parts.count > 6 ? parts[6] : ""
                    )
                    items.append(container)
                }
            }
            return items
        } catch {
            return []
        }
    }
    
    private func loadDiskUsage() -> [DockerDiskUsage] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: dockerPath)
        process.arguments = ["system", "df"]
        let pipe = Pipe()
        process.standardOutput = pipe
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return [] }
            
            var items: [DockerDiskUsage] = []
            let lines = output.components(separatedBy: .newlines)
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("Images") || trimmed.hasPrefix("Containers") || trimmed.hasPrefix("Local Volumes") || trimmed.hasPrefix("Build Cache") {
                    let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    if parts.count >= 4 {
                        let type = parts[0] + (parts.count > 1 && parts[1] == "Volumes" ? " Volumes" : (parts.count > 1 && parts[1] == "Cache" ? " Cache" : ""))
                        let usage = DockerDiskUsage(
                            type: type,
                            totalCount: Int(parts[type.contains(" ") ? 2 : 1]) ?? 0,
                            activeCount: Int(parts[type.contains(" ") ? 3 : 2]) ?? 0,
                            size: parts.count > 4 ? parts[type.contains(" ") ? 4 : 3] : "0B",
                            reclaimable: parts.last ?? "0B"
                        )
                        items.append(usage)
                    }
                }
            }
            return items
        } catch {
            return []
        }
    }
    
    // Container Actions
    func startContainer(id: String) {
        runDockerCommand(["start", id]) { [weak self] _ in self?.refreshAll() }
    }
    
    func stopContainer(id: String) {
        runDockerCommand(["stop", id]) { [weak self] _ in self?.refreshAll() }
    }
    
    func restartContainer(id: String) {
        runDockerCommand(["restart", id]) { [weak self] _ in self?.refreshAll() }
    }
    
    func removeContainer(id: String) {
        runDockerCommand(["rm", "-f", id]) { [weak self] _ in self?.refreshAll() }
    }
    
    // Purge Reclaimer Actions
    func purgeImages() {
        runDockerCommand(["image", "prune", "-a", "-f"]) { [weak self] _ in self?.refreshAll() }
    }
    
    func purgeStoppedContainers() {
        runDockerCommand(["container", "prune", "-f"]) { [weak self] _ in self?.refreshAll() }
    }
    
    func purgeVolumes() {
        runDockerCommand(["volume", "prune", "-f"]) { [weak self] _ in self?.refreshAll() }
    }
    
    func purgeBuildCache() {
        runDockerCommand(["builder", "prune", "-a", "-f"]) { [weak self] _ in self?.refreshAll() }
    }
    
    func purgeEverything() {
        runDockerCommand(["system", "prune", "-a", "--volumes", "-f"]) { [weak self] _ in self?.refreshAll() }
    }
    
    private func runDockerCommand(_ args: [String], completion: @escaping (Bool) -> Void) {
        guard !dockerPath.isEmpty else { completion(false); return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: self?.dockerPath ?? "/usr/local/bin/docker")
            process.arguments = args
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            try? process.run()
            process.waitUntilExit()
            let success = process.terminationStatus == 0
            DispatchQueue.main.async { completion(success) }
        }
    }
}
