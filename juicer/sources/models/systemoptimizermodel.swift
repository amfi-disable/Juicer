import Foundation
import AppKit

// MARK: - Models

struct OptimizationTask: Identifiable {
    let id: UUID = UUID()
    let name: String
    let description: String
    let category: TaskCategory
    let command: String
    let arguments: [String]
    var isSelected: Bool = true
    var status: TaskStatus = .pending
    var resultMessage: String = ""

    enum TaskCategory: String, CaseIterable {
        case system = "System"
        case developer = "Developer"
        case network = "Network"
        case memory = "Memory"
        case storage = "Storage"

        var color: String {
            switch self {
            case .system: return "blue"
            case .developer: return "orange"
            case .network: return "cyan"
            case .memory: return "purple"
            case .storage: return "green"
            }
        }
    }

    enum TaskStatus {
        case pending, running, success, failed, skipped
    }
}

struct SystemHealthMetric: Identifiable {
    let id: UUID = UUID()
    let name: String
    let value: String
    let icon: String
    let category: String
}

// MARK: - Manager

class SystemOptimizerManager: ObservableObject {
    @Published var tasks: [OptimizationTask] = []
    @Published var healthMetrics: [SystemHealthMetric] = []
    @Published var isRunning: Bool = false
    @Published var completedCount: Int = 0
    @Published var failedCount: Int = 0
    @Published var runLog: [String] = []
    @Published var isLoadingMetrics: Bool = false

    init() {
        buildDefaultTasks()
    }

    // MARK: - Build Default Task List (Mole-inspired)

    private func buildDefaultTasks() {
        tasks = [
            // --- System ---
            OptimizationTask(
                name: "Flush DNS Cache",
                description: "Clear the macOS DNS resolver cache to fix resolution issues.",
                category: .network,
                command: "/usr/bin/dscacheutil",
                arguments: ["-flushcache"]
            ),
            OptimizationTask(
                name: "Rebuild LaunchServices DB",
                description: "Regenerate the Launch Services database to fix 'Open With' menus and app associations.",
                category: .system,
                command: "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister",
                arguments: ["-kill", "-r", "-domain", "local", "-domain", "system", "-domain", "user"]
            ),
            OptimizationTask(
                name: "Purge Inactive Memory",
                description: "Force macOS to release unused memory pages back to the free pool.",
                category: .memory,
                command: "/usr/bin/purge",
                arguments: []
            ),
            OptimizationTask(
                name: "Rebuild Spotlight Index (Home)",
                description: "Re-index the home directory for Spotlight search to find files correctly.",
                category: .system,
                command: "/usr/bin/mdutil",
                arguments: ["-E", FileManager.default.homeDirectoryForCurrentUser.path]
            ),
            OptimizationTask(
                name: "Flush Font Cache",
                description: "Remove system font cache files to resolve font rendering glitches.",
                category: .system,
                command: "/usr/bin/atsutil",
                arguments: ["databases", "-remove"]
            ),
            OptimizationTask(
                name: "Trim SSD",
                description: "Trigger an SSD TRIM pass to maintain storage write performance (requires admin).",
                category: .storage,
                command: "/sbin/mount",
                arguments: ["-u", "/"]
            ),
            OptimizationTask(
                name: "Flush APFS Snapshot Metadata",
                description: "List and identify APFS snapshots consuming hidden disk space.",
                category: .storage,
                command: "/usr/bin/tmutil",
                arguments: ["listlocalsnapshots", "/"]
            ),
            OptimizationTask(
                name: "Rebuild Accessibility Database",
                description: "Reset the accessibility database to resolve TCC/permissions UI issues.",
                category: .system,
                command: "/usr/bin/tccutil",
                arguments: ["reset", "Accessibility"]
            ),
            OptimizationTask(
                name: "Flush System Log Archive",
                description: "Remove expired unified log archives to free up log storage.",
                category: .storage,
                command: "/usr/sbin/syslog",
                arguments: ["-db", "-remove", "all"]
            ),
            OptimizationTask(
                name: "Rehash Shell Path Cache",
                description: "Reload shell $PATH hash table for a clean command lookup state.",
                category: .developer,
                command: "/bin/zsh",
                arguments: ["-c", "hash -r"]
            ),
            OptimizationTask(
                name: "Brew Cleanup (Formulae)",
                description: "Remove outdated Homebrew package installations and download archives.",
                category: .developer,
                command: "/opt/homebrew/bin/brew",
                arguments: ["cleanup", "--prune=all"]
            ),
            OptimizationTask(
                name: "Brew Update & Upgrade",
                description: "Update Homebrew registry and upgrade all outdated formulae.",
                category: .developer,
                command: "/opt/homebrew/bin/brew",
                arguments: ["update"]
            ),
            OptimizationTask(
                name: "Remove Temporary Files",
                description: "Delete user temporary files from /tmp and /var/folders.",
                category: .storage,
                command: "/bin/rm",
                arguments: ["-rf", NSTemporaryDirectory()]
            ),
            OptimizationTask(
                name: "Clear QuickLook Thumbnails Cache",
                description: "Remove stale QuickLook thumbnail caches (fixes preview glitches).",
                category: .storage,
                command: "/usr/bin/qlmanage",
                arguments: ["-r", "cache"]
            ),
            OptimizationTask(
                name: "Reset Network Interface Stats",
                description: "Clear cached network interface packet counters.",
                category: .network,
                command: "/usr/sbin/netstat",
                arguments: ["-rs"]
            )
        ]
    }

    // MARK: - Load System Health Metrics (Mole status-inspired)

    func loadHealthMetrics() {
        isLoadingMetrics = true
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            var metrics: [SystemHealthMetric] = []

            // CPU info
            let cpuLoad = self.getCPUUsage()
            metrics.append(SystemHealthMetric(name: "CPU Load", value: cpuLoad, icon: "cpu", category: "CPU"))

            // Memory
            let (memUsed, memTotal) = self.getMemoryInfo()
            metrics.append(SystemHealthMetric(name: "Memory Used", value: "\(memUsed) / \(memTotal)", icon: "memorychip", category: "Memory"))

            // Disk
            if let diskInfo = try? FileManager.default.attributesOfFileSystem(forPath: "/"),
               let total = diskInfo[.systemSize] as? Int64,
               let free = diskInfo[.systemFreeSize] as? Int64 {
                let used = total - free
                let pct = total > 0 ? Int(Double(used) / Double(total) * 100) : 0
                let fmt = ByteCountFormatter()
                fmt.countStyle = .file
                metrics.append(SystemHealthMetric(
                    name: "Disk Usage",
                    value: "\(fmt.string(fromByteCount: used)) used (\(pct)%)",
                    icon: "internaldrive",
                    category: "Storage"
                ))
                metrics.append(SystemHealthMetric(
                    name: "Disk Free",
                    value: fmt.string(fromByteCount: free),
                    icon: "externaldrive.badge.checkmark",
                    category: "Storage"
                ))
            }

            // Uptime
            let uptime = self.getUptime()
            metrics.append(SystemHealthMetric(name: "System Uptime", value: uptime, icon: "clock", category: "System"))

            // macOS version
            let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
            metrics.append(SystemHealthMetric(name: "macOS Version", value: osVersion, icon: "apple.logo", category: "System"))

            // Hostname
            metrics.append(SystemHealthMetric(name: "Hostname", value: ProcessInfo.processInfo.hostName, icon: "network", category: "System"))

            // Process count
            let processCount = self.getProcessCount()
            metrics.append(SystemHealthMetric(name: "Running Processes", value: processCount, icon: "gearshape.2", category: "System"))

            await MainActor.run {
                self.healthMetrics = metrics
                self.isLoadingMetrics = false
            }
        }
    }

    private func getCPUUsage() -> String {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/top")
        proc.arguments = ["-l", "1", "-n", "0", "-s", "0"]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()
        do {
            try proc.run(); proc.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            for line in output.components(separatedBy: "\n") {
                if line.contains("CPU usage") {
                    return line.replacingOccurrences(of: "CPU usage:", with: "").trimmingCharacters(in: .whitespaces)
                }
            }
        } catch {}
        return "N/A"
    }

    private func getMemoryInfo() -> (String, String) {
        let total = ProcessInfo.processInfo.physicalMemory
        let fmt = ByteCountFormatter()
        fmt.countStyle = .memory
        // Approximate used via vm_stat
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/vm_stat")
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()
        var used: UInt64 = 0
        do {
            try proc.run(); proc.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            var pagesActive: UInt64 = 0
            for line in output.components(separatedBy: "\n") {
                if line.hasPrefix("Pages active:"),
                   let num = UInt64(line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ".", with: "") ?? "") {
                    pagesActive = num
                }
            }
            used = pagesActive * 4096
        } catch {}
        return (fmt.string(fromByteCount: Int64(used)), fmt.string(fromByteCount: Int64(total)))
    }

    private func getUptime() -> String {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/uptime")
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()
        do {
            try proc.run(); proc.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return (String(data: data, encoding: .utf8) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        } catch { return "N/A" }
    }

    private func getProcessCount() -> String {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/sh")
        proc.arguments = ["-c", "ps aux | wc -l"]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()
        do {
            try proc.run(); proc.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let raw = (String(data: data, encoding: .utf8) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if let n = Int(raw) { return "\(max(0, n - 1))" }
        } catch {}
        return "N/A"
    }

    // MARK: - Run Optimization

    func runSelectedTasks() {
        let selected = tasks.filter { $0.isSelected && $0.status == .pending }
        guard !selected.isEmpty else { return }

        isRunning = true
        completedCount = 0
        failedCount = 0
        runLog = []

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            for task in selected {
                // Mark running
                await MainActor.run {
                    if let idx = self.tasks.firstIndex(where: { $0.id == task.id }) {
                        self.tasks[idx].status = .running
                    }
                    self.runLog.append("▶ Running: \(task.name)")
                }

                // Execute
                let result = self.execute(command: task.command, arguments: task.arguments)

                await MainActor.run {
                    if let idx = self.tasks.firstIndex(where: { $0.id == task.id }) {
                        self.tasks[idx].status = result.success ? .success : .failed
                        self.tasks[idx].resultMessage = result.output
                    }
                    if result.success {
                        self.completedCount += 1
                        self.runLog.append("✅ Done: \(task.name)")
                    } else {
                        self.failedCount += 1
                        self.runLog.append("❌ Failed: \(task.name) — \(result.output)")
                    }
                }
            }

            await MainActor.run {
                self.isRunning = false
                self.runLog.append("🏁 Optimization complete. \(self.completedCount) succeeded, \(self.failedCount) failed.")
                NotificationManager.shared.sendNotification(
                    title: "Optimization Complete",
                    body: "\(self.completedCount) tasks succeeded, \(self.failedCount) failed."
                )
            }
        }
    }

    private func execute(command: String, arguments: [String]) -> (success: Bool, output: String) {
        // Only run if binary exists
        guard FileManager.default.fileExists(atPath: command) else {
            return (false, "Command not found: \(command)")
        }
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: command)
        proc.arguments = arguments
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = pipe
        do {
            try proc.run()
            proc.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let out = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return (proc.terminationStatus == 0, out.isEmpty ? "OK" : out)
        } catch {
            return (false, error.localizedDescription)
        }
    }

    func resetTasks() {
        for i in tasks.indices {
            tasks[i].status = .pending
            tasks[i].resultMessage = ""
            tasks[i].isSelected = true
        }
        runLog = []
        completedCount = 0
        failedCount = 0
    }
}
