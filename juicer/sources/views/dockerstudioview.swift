import SwiftUI
import AppKit

struct DockerContainerItem: Identifiable {
    var id: String { containerId }
    let containerId: String
    let name: String
    let image: String
    let status: String
    let ports: String
    let isRunning: Bool
}

class DockerStudioManager: ObservableObject {
    @Published var containers: [DockerContainerItem] = []
    @Published var isDockerRunning = false
    @Published var isScanning = false
    @Published var selectedContainerLogs = ""
    @Published var statusMessage = ""
    
    init() {
        self.checkDockerState()
    }
    
    func checkDockerState() {
        self.isScanning = true
        Task.detached(priority: .userInitiated) {
            let output = self.runShellCommand("docker ps -a --format \"{{.ID}}|{{.Names}}|{{.Image}}|{{.Status}}|{{.Ports}}\"")
            let isRunning = !output.isEmpty || FileManager.default.fileExists(atPath: "/var/run/docker.sock")
            
            var items: [DockerContainerItem] = []
            let lines = output.components(separatedBy: "\n")
            for line in lines {
                let parts = line.components(separatedBy: "|")
                if parts.count >= 5 {
                    let id = parts[0]
                    let name = parts[1]
                    let image = parts[2]
                    let status = parts[3]
                    let ports = parts[4]
                    let running = status.lowercased().contains("up")
                    items.append(DockerContainerItem(containerId: id, name: name, image: image, status: status, ports: ports, isRunning: running))
                }
            }
            
            await MainActor.run {
                self.containers = items
                self.isDockerRunning = isRunning
                self.isScanning = false
                if items.isEmpty {
                    self.statusMessage = isRunning ? "Docker daemon is active. No containers found." : "Docker daemon not running or not installed."
                } else {
                    self.statusMessage = "Found \(items.count) container(s)."
                }
            }
        }
    }
    
    func startContainer(id: String) {
        runShellAsync("docker start \(id)") { self.checkDockerState() }
    }
    
    func stopContainer(id: String) {
        runShellAsync("docker stop \(id)") { self.checkDockerState() }
    }
    
    func fetchLogs(id: String) {
        Task.detached(priority: .userInitiated) {
            let logs = self.runShellCommand("docker logs --tail 100 \(id)")
            await MainActor.run {
                self.selectedContainerLogs = logs.isEmpty ? "No log output available for container." : logs
            }
        }
    }
    
    func pruneSystem() {
        runShellAsync("docker system prune -f") { self.checkDockerState() }
    }
    
    private func runShellCommand(_ cmd: String) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", cmd]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch { return "" }
    }
    
    private func runShellAsync(_ cmd: String, completion: @escaping () -> Void) {
        Task.detached(priority: .userInitiated) {
            _ = self.runShellCommand(cmd)
            await MainActor.run { completion() }
        }
    }
}

struct dockerstudioview: View {
    @StateObject private var manager = DockerStudioManager()
    @State private var selectedTab = "Containers"
    
    var body: some View {
        VStack(spacing: 0) {
            JuicerFeatureHeader(
                title: "Juicer Docker Studio",
                subtitle: "Inspect running containers, stream logs, manage compose stacks, and purge build caches.",
                icon: "cube.fill",
                refreshing: manager.isScanning,
                action: { manager.checkDockerState() }
            )
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            
            Divider()
            
            HStack {
                Picker("", selection: $selectedTab) {
                    Text("Containers (\(manager.containers.count))").tag("Containers")
                    Text("Log Streamer").tag("Logs")
                    Text("System Prune").tag("Prune")
                }
                .pickerStyle(.segmented)
                .frame(width: 320)
                
                Spacer()
                
                Text(manager.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            
            Divider()
            
            if selectedTab == "Containers" {
                containersListView()
            } else if selectedTab == "Logs" {
                logsView()
            } else {
                pruneView()
            }
        }
        .allowWindowDragAndFit()
    }
    
    @ViewBuilder
    private func containersListView() -> some View {
        if manager.containers.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "cube.transparent")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)
                Text(manager.statusMessage)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Button("Refresh Docker Status") { manager.checkDockerState() }
                    .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(manager.containers) { item in
                HStack {
                    Circle()
                        .fill(item.isRunning ? Color.green : Color.gray)
                        .frame(width: 10, height: 10)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(item.name).bold()
                            Text(item.containerId).font(.caption.monospaced()).foregroundStyle(.secondary)
                        }
                        Text("\(item.image) • Ports: \(item.ports.isEmpty ? "None" : item.ports)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Logs") {
                        manager.fetchLogs(id: item.containerId)
                        selectedTab = "Logs"
                    }
                    .buttonStyle(.bordered)
                    
                    if item.isRunning {
                        Button("Stop") { manager.stopContainer(id: item.containerId) }
                            .buttonStyle(.bordered)
                            .tint(.orange)
                    } else {
                        Button("Start") { manager.startContainer(id: item.containerId) }
                            .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.vertical, 4)
            }
            .listStyle(.inset)
        }
    }
    
    @ViewBuilder
    private func logsView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Container Log Stream Output").font(.headline)
            TextEditor(text: .constant(manager.selectedContainerLogs.isEmpty ? "Select a container and click 'Logs' to inspect output." : manager.selectedContainerLogs))
                .font(.system(.caption, design: .monospaced))
                .cornerRadius(8)
        }
        .padding()
    }
    
    @ViewBuilder
    private func pruneView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "trash.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            Text("Docker System Cache Purge")
                .font(.title2.bold())
            Text("Reclaim disk space by purging stopped containers, unused networks, dangling images, and build cache (`docker system prune -f`).")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 450)
            
            Button("Execute Docker System Prune") {
                manager.pruneSystem()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
