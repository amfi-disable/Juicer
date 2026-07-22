import SwiftUI
import AppKit

struct dockerstudioview: View {
    @StateObject private var manager = DockerManager.shared
    @State private var selectedTab = 0
    @State private var selectedContainerID: String? = nil
    @State private var logOutput: String = ""
    @State private var logSearch: String = ""
    @State private var isStreamingLogs = false
    @State private var showingPurgeConfirm = false
    @State private var purgeTarget: String = "Everything"
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Banner
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 52, height: 52)
                    Image(systemName: "cube.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Juicer Docker Studio")
                            .font(.title2).bold()
                        
                        HStack(spacing: 5) {
                            Circle()
                                .fill(manager.isDaemonRunning ? Color.green : Color.red)
                                .frame(width: 7, height: 7)
                            Text(manager.isDaemonRunning ? "DAEMON ACTIVE" : (manager.isDockerInstalled ? "DAEMON STOPPED" : "NOT INSTALLED"))
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(manager.isDaemonRunning ? .green : .red)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background((manager.isDaemonRunning ? Color.green : Color.red).opacity(0.14), in: Capsule())
                    }
                    
                    Text("Container workbench, disk space reclaimer, log streamer, and stack manager")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: { manager.refreshAll() }) {
                    Label("Refresh Status", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(manager.isRefreshing)
            }
            .padding(20)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Picker Tab Bar
            HStack {
                Picker("", selection: $selectedTab) {
                    Text("Containers (\(manager.containers.count))").tag(0)
                    Text("Disk Reclaimer").tag(1)
                    Text("Log Streamer").tag(2)
                    Text("Compose Stacks").tag(3)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 540)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Tab Content
            if !manager.isDockerInstalled {
                dockerNotInstalledView()
            } else if !manager.isDaemonRunning {
                dockerDaemonStoppedView()
            } else {
                switch selectedTab {
                case 0:
                    containersTabView()
                case 1:
                    reclaimerTabView()
                case 2:
                    logsTabView()
                default:
                    composeTabView()
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            manager.refreshAll()
        }
    }
    
    // MARK: - Tab 1: Containers List
    @ViewBuilder
    private func containersTabView() -> some View {
        if manager.containers.isEmpty {
            VStack(spacing: 14) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.secondary)
                Text("No Containers Found")
                    .font(.title3).bold()
                Text("Run `docker run` or launch a compose stack to start containers.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(manager.containers) { container in
                        HStack(spacing: 14) {
                            Circle()
                                .fill(container.isRunning ? Color.green : Color.gray)
                                .frame(width: 10, height: 10)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 8) {
                                    Text(container.name)
                                        .font(.headline.bold())
                                    Text(container.id.prefix(12))
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                                Text("Image: \(container.image)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if !container.ports.isEmpty {
                                    Text("Ports: \(container.ports)")
                                        .font(.caption2.monospaced())
                                        .foregroundColor(.cyan)
                                }
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                if container.isRunning {
                                    Button("Stop") { manager.stopContainer(id: container.id) }
                                        .buttonStyle(.bordered)
                                        .tint(.orange)
                                    Button("Restart") { manager.restartContainer(id: container.id) }
                                        .buttonStyle(.bordered)
                                } else {
                                    Button("Start") { manager.startContainer(id: container.id) }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.green)
                                }
                                
                                Button("Logs") {
                                    selectedContainerID = container.id
                                    selectedTab = 2
                                    fetchLogs(for: container.id)
                                }
                                .buttonStyle(.bordered)
                                
                                Button(action: { manager.removeContainer(id: container.id) }) {
                                    Image(systemName: "trash").foregroundColor(.red)
                                }
                                .buttonStyle(.bordered)
                                .help("Remove Container")
                            }
                        }
                        .padding(14)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.12), lineWidth: 1))
                    }
                }
                .padding(20)
            }
        }
    }
    
    // MARK: - Tab 2: Disk Reclaimer
    @ViewBuilder
    private func reclaimerTabView() -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Warning / Action Card
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Docker System Space Reclaimer")
                            .font(.headline.bold())
                        Text("Purge unused build caches, stopped containers, dangling images, and volumes to reclaim disk space.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Purging System All...") {
                        manager.purgeEverything()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding(16)
                .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.2), lineWidth: 1))
                
                // System DF Breakdown Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    purgeCard(title: "Dangling Images", icon: "shippingbox", actionTitle: "Purge Images", action: { manager.purgeImages() })
                    purgeCard(title: "Stopped Containers", icon: "square.slash", actionTitle: "Purge Containers", action: { manager.purgeStoppedContainers() })
                    purgeCard(title: "Unused Volumes", icon: "internaldrive", actionTitle: "Purge Volumes", action: { manager.purgeVolumes() })
                    purgeCard(title: "Build Cache", icon: "hammer.fill", actionTitle: "Purge Build Cache", action: { manager.purgeBuildCache() })
                }
            }
            .padding(20)
        }
    }
    
    @ViewBuilder
    private func purgeCard(title: String, icon: String, actionTitle: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline.bold())
            }
            Text("Reclaim disk space occupied by idle or orphaned items.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button(actionTitle, action: action)
                    .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.secondary.opacity(0.12), lineWidth: 1))
    }
    
    // MARK: - Tab 3: Log Streamer
    @ViewBuilder
    private func logsTabView() -> some View {
        VStack(spacing: 12) {
            HStack {
                Picker("Container", selection: $selectedContainerID) {
                    Text("Select a container...").tag(String?.none)
                    ForEach(manager.containers) { c in
                        Text("\(c.name) (\(c.id.prefix(8)))").tag(String?.some(c.id))
                    }
                }
                .frame(maxWidth: 320)
                
                TextField("Filter log lines...", text: $logSearch)
                    .textFieldStyle(.roundedBorder)
                
                Button("Refresh Logs") {
                    if let id = selectedContainerID { fetchLogs(for: id) }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            
            // Console Terminal Box
            ScrollView {
                Text(filteredLogs)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
            }
            .background(Color.black, in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    var filteredLogs: String {
        guard !logSearch.isEmpty else { return logOutput.isEmpty ? "Select a container above to stream logs..." : logOutput }
        let lines = logOutput.components(separatedBy: .newlines)
        return lines.filter { $0.localizedCaseInsensitiveContains(logSearch) }.joined(separator: "\n")
    }
    
    private func fetchLogs(for containerID: String) {
        guard !manager.dockerPath.isEmpty else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: manager.dockerPath)
            process.arguments = ["logs", "--tail", "250", containerID]
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            try? process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let text = String(data: data, encoding: .utf8) ?? "No log output received."
            DispatchQueue.main.async {
                self.logOutput = text
            }
        }
    }
    
    // MARK: - Tab 4: Compose Stacks
    @ViewBuilder
    private func composeTabView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 48))
                .foregroundColor(.cyan)
            Text("Compose Stack Manager")
                .font(.title2).bold()
            Text("Workspace scanner for `docker-compose.yml` services.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Active Project Workspaces Monitored: Juicer Studio")
                .font(.caption.monospaced())
                .foregroundColor(.accentColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
    }
    
    @ViewBuilder
    private func dockerNotInstalledView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 52))
                .foregroundColor(.orange)
            Text("Docker Not Detected")
                .font(.title2).bold()
            Text("Juicer requires Docker Desktop, OrbStack, or Colima to inspect containers.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 500)
            
            Button("Install via Homebrew Cask (`brew install --cask orbstack`)") {
                if let url = URL(string: "https://orbstack.dev") { NSWorkspace.shared.open(url) }
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    @ViewBuilder
    private func dockerDaemonStoppedView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 52))
                .foregroundColor(.orange)
            Text("Docker Daemon Not Running")
                .font(.title2).bold()
            Text("Docker CLI was found at `\(manager.dockerPath)`, but the background daemon is currently offline.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 500)
            
            Button("Check / Refresh Daemon") {
                manager.refreshAll()
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}
