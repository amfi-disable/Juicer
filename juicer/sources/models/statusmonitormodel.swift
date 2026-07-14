import Foundation
import AppKit

// MARK: - Data Models (Mole mo-status inspired)

struct CPUStatusData {
    var usagePercent: Double = 0
    var coreCount: Int = ProcessInfo.processInfo.processorCount
    var loadAvg1: Double = 0
    var loadAvg5: Double = 0
    var loadAvg15: Double = 0
    var perCoreUsage: [Double] = []
}

struct MemoryStatusData {
    var totalBytes: UInt64 = ProcessInfo.processInfo.physicalMemory
    var usedBytes: UInt64 = 0
    var freeBytes: UInt64 = 0
    var usedPercent: Double = 0
    var pressure: String = "normal"  // "normal" | "warn" | "critical"
    var swapUsedBytes: UInt64 = 0
    var swapTotalBytes: UInt64 = 0
}

struct NetworkSpeedData {
    var rxBytesPerSec: Double = 0
    var txBytesPerSec: Double = 0
    var interfaceName: String = ""
    var totalRxBytes: UInt64 = 0
    var totalTxBytes: UInt64 = 0
}

struct TopProcessEntry: Identifiable {
    let id = UUID()
    var pid: Int
    var name: String
    var cpuPercent: Double
    var memPercent: Double
    var memBytes: UInt64
}

struct ProcessMonitorEntry: Identifiable {
    let id = UUID()
    var pid: Int
    var ppid: Int
    var name: String
    var command: String
    var cpuPercent: Double
    var memPercent: Double
    var memBytes: UInt64
}

struct HardwareInfoData {
    var modelName: String = "Mac"
    var chipName: String = ""
    var osVersion: String = ProcessInfo.processInfo.operatingSystemVersionString
    var totalRAMFormatted: String = ""
    var serialNumber: String = ""
}

struct HealthScoreData {
    var score: Int = 100
    var grade: String = "Excellent"
    var cpuPenalty: Double = 0
    var memPenalty: Double = 0
    var tips: [String] = []

    // Mole-inspired thresholds
    static func compute(cpu: CPUStatusData, mem: MemoryStatusData) -> HealthScoreData {
        var score = 100.0
        var tips: [String] = []

        // CPU penalty (Mole uses cpuNormalThreshold=50, cpuHighThreshold=85)
        if cpu.usagePercent > 85 {
            let penalty = 30.0 * min((cpu.usagePercent - 50) / 85, 1.0)
            score -= penalty
            tips.append("CPU is under heavy load (\(Int(cpu.usagePercent))%).")
        } else if cpu.usagePercent > 50 {
            let penalty = 15.0 * (cpu.usagePercent - 50) / 35
            score -= penalty
        }

        // Memory penalty (Mole memNormalThreshold=70, memHighThreshold=88)
        if mem.usedPercent > 88 {
            let penalty = 25.0 * min((mem.usedPercent - 70) / 70, 1.0)
            score -= penalty
            tips.append("Memory usage is very high (\(Int(mem.usedPercent))%).")
        } else if mem.usedPercent > 70 {
            let penalty = 12.0 * (mem.usedPercent - 70) / 18
            score -= penalty
        }

        // Pressure penalty
        if mem.pressure == "critical" {
            score -= 15
            tips.append("System memory pressure is critical — consider closing apps.")
        } else if mem.pressure == "warn" {
            score -= 5
            tips.append("Memory pressure is elevated.")
        }

        if score > 95 && tips.isEmpty {
            tips.append("Your system is running optimally. No action needed.")
        }

        let finalScore = max(0, min(100, Int(score)))
        let grade: String
        if finalScore >= 85 { grade = "Excellent" }
        else if finalScore >= 65 { grade = "Good" }
        else if finalScore >= 45 { grade = "Fair" }
        else { grade = "Poor" }

        return HealthScoreData(score: finalScore, grade: grade, tips: tips)
    }
}

// MARK: - Manager

class StatusMonitorManager: ObservableObject {
    @Published var cpu = CPUStatusData()
    @Published var memory = MemoryStatusData()
    @Published var network = NetworkSpeedData()
    @Published var topProcesses: [TopProcessEntry] = []
    @Published var allProcesses: [ProcessMonitorEntry] = []
    @Published var hardware = HardwareInfoData()
    @Published var health = HealthScoreData()
    @Published var isLoading: Bool = true
    @Published var processSearchQuery: String = ""
    @Published var processSortKey: ProcessSortKey = .cpu
    @Published var isRefreshing: Bool = false

    enum ProcessSortKey: String, CaseIterable {
        case cpu = "CPU %"
        case mem = "Memory"
        case pid = "PID"
        case name = "Name"
    }

    private var timer: Timer?
    private var prevNetworkBytes: (rx: UInt64, tx: UInt64, time: Date)?

    var filteredProcesses: [ProcessMonitorEntry] {
        let sorted: [ProcessMonitorEntry]
        switch processSortKey {
        case .cpu: sorted = allProcesses.sorted { $0.cpuPercent > $1.cpuPercent }
        case .mem: sorted = allProcesses.sorted { $0.memBytes > $1.memBytes }
        case .pid: sorted = allProcesses.sorted { $0.pid < $1.pid }
        case .name: sorted = allProcesses.sorted { $0.name < $1.name }
        }
        if processSearchQuery.isEmpty { return sorted }
        return sorted.filter {
            $0.name.localizedCaseInsensitiveContains(processSearchQuery) ||
            $0.command.localizedCaseInsensitiveContains(processSearchQuery) ||
            String($0.pid).contains(processSearchQuery)
        }
    }

    // MARK: - Start

    func start() {
        collectHardwareInfo()
        refresh()
        timer = Timer(timeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func refresh() {
        isRefreshing = true
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            let cpu = self.collectCPU()
            let mem = self.collectMemory()
            let net = self.collectNetwork()
            let procs = self.collectProcesses()
            let health = HealthScoreData.compute(cpu: cpu, mem: mem)

            let top = procs.sorted { $0.cpuPercent > $1.cpuPercent }.prefix(5).map {
                TopProcessEntry(pid: $0.pid, name: $0.name, cpuPercent: $0.cpuPercent, memPercent: $0.memPercent, memBytes: $0.memBytes)
            }

            await MainActor.run {
                self.cpu = cpu
                self.memory = mem
                self.network = net
                self.allProcesses = procs
                self.topProcesses = top
                self.health = health
                self.isLoading = false
                self.isRefreshing = false
            }
        }
    }

    // MARK: - CPU Collection (Mole-inspired ps approach)

    private func collectCPU() -> CPUStatusData {
        var data = CPUStatusData()
        let coreCount = max(1, ProcessInfo.processInfo.processorCount)
        data.coreCount = coreCount

        // CPU usage via `ps`
        if let out = shell("/bin/sh", ["-c", "ps -Aceo pcpu"]) {
            var total = 0.0
            for line in out.split(separator: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if let val = Double(trimmed) { total += val }
            }
            data.usagePercent = min(100.0, total / Double(coreCount))
        }

        // Load averages via sysctl
        if let out = shell("/usr/sbin/sysctl", ["-n", "vm.loadavg"]) {
            // Format: { 2.50 1.80 1.40 }
            let cleaned = out.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "{", with: "")
                .replacingOccurrences(of: "}", with: "")
            let parts = cleaned.split(separator: " ").compactMap { Double($0) }
            if parts.count >= 3 {
                data.loadAvg1 = parts[0]
                data.loadAvg5 = parts[1]
                data.loadAvg15 = parts[2]
            }
        }

        return data
    }

    // MARK: - Memory Collection (Mole vm_stat approach)

    private func collectMemory() -> MemoryStatusData {
        var data = MemoryStatusData()
        let total = ProcessInfo.processInfo.physicalMemory
        data.totalBytes = total

        // Parse vm_stat for page-based usage
        if let out = shell("/usr/bin/vm_stat", []) {
            var pageSize: UInt64 = 16384
            var pagesActive: UInt64 = 0
            var pagesWired: UInt64 = 0
            var pagesCompressed: UInt64 = 0
            var pagesFree: UInt64 = 0

            for line in out.split(separator: "\n") {
                let str = String(line)
                // page size
                if str.contains("page size of"), let range = str.range(of: "page size of ") {
                    let rest = String(str[range.upperBound...])
                    if let val = UInt64(rest.components(separatedBy: " ").first ?? "") {
                        pageSize = val
                    }
                }
                func parseVmStatLine(_ prefix: String) -> UInt64 {
                    if str.contains(prefix) {
                        let parts = str.components(separatedBy: ":")
                        if parts.count == 2 {
                            let numStr = parts[1].trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ".", with: "")
                            return UInt64(numStr) ?? 0
                        }
                    }
                    return 0
                }
                if str.hasPrefix("Pages active:") { pagesActive = parseVmStatLine("Pages active:") }
                if str.hasPrefix("Pages wired down:") { pagesWired = parseVmStatLine("Pages wired down:") }
                if str.hasPrefix("Pages occupied by compressor:") { pagesCompressed = parseVmStatLine("Pages occupied by compressor:") }
                if str.hasPrefix("Pages free:") { pagesFree = parseVmStatLine("Pages free:") }
            }

            let used = (pagesActive + pagesWired + pagesCompressed) * pageSize
            let free = pagesFree * pageSize
            data.usedBytes = used
            data.freeBytes = free
            data.usedPercent = total > 0 ? Double(used) / Double(total) * 100 : 0
        }

        // Memory pressure
        if let out = shell("/usr/bin/memory_pressure", []) {
            let lower = out.lowercased()
            if lower.contains("critical") { data.pressure = "critical" }
            else if lower.contains("warn") { data.pressure = "warn" }
            else { data.pressure = "normal" }
        }

        // Swap
        if let out = shell("/usr/sbin/sysctl", ["-n", "vm.swapusage"]) {
            // "total = 3072.00M  used = 1024.00M  free = 2048.00M  (encrypted)"
            func parseMB(_ token: String) -> UInt64 {
                if let val = Double(token.replacingOccurrences(of: "M", with: "")) {
                    return UInt64(val * 1024 * 1024)
                }
                return 0
            }
            let parts = out.components(separatedBy: "=")
            for (i, part) in parts.enumerated() {
                let trimmed = part.trimmingCharacters(in: .whitespaces)
                if i == 1 { // total
                    data.swapTotalBytes = parseMB(trimmed.components(separatedBy: " ").first ?? "")
                } else if i == 2 { // used
                    data.swapUsedBytes = parseMB(trimmed.components(separatedBy: " ").first ?? "")
                }
            }
        }

        return data
    }

    // MARK: - Network Collection (Mole netstat delta approach)

    private func collectNetwork() -> NetworkSpeedData {
        var data = NetworkSpeedData()

        guard let out = shell("/usr/sbin/netstat", ["-ibnd"]) else { return data }

        var bestRx: UInt64 = 0
        var bestTx: UInt64 = 0
        var bestIface = ""

        // Parse each interface line, pick the one with most traffic
        for line in out.split(separator: "\n").dropFirst() {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 10 else { continue }
            let iface = String(parts[0])
            // Skip loopback, utun, awdl, etc.
            let skip = ["lo", "utun", "awdl", "llw", "bridge", "gif", "stf", "anpi", "ap"]
            if skip.contains(where: { iface.hasPrefix($0) }) { continue }

            // Columns vary; try parsing Ibytes and Obytes
            // netstat -ibnd: Name Mtu Network Address Ipkts Ierrs Ibytes Opkts Oerrs Obytes...
            if let rxVal = UInt64(parts[6]), let txVal = UInt64(parts[9]) {
                if rxVal + txVal > bestRx + bestTx {
                    bestRx = rxVal; bestTx = txVal; bestIface = iface
                }
            }
        }

        data.totalRxBytes = bestRx
        data.totalTxBytes = bestTx
        data.interfaceName = bestIface

        // Compute per-second delta
        let now = Date()
        if let prev = prevNetworkBytes {
            let elapsed = now.timeIntervalSince(prev.time)
            if elapsed > 0.1 {
                let rxDelta = bestRx > prev.rx ? bestRx - prev.rx : 0
                let txDelta = bestTx > prev.tx ? bestTx - prev.tx : 0
                data.rxBytesPerSec = Double(rxDelta) / elapsed
                data.txBytesPerSec = Double(txDelta) / elapsed
            }
        }
        prevNetworkBytes = (rx: bestRx, tx: bestTx, time: now)

        return data
    }

    // MARK: - Process Collection (Mole ps approach)

    private func collectProcesses() -> [ProcessMonitorEntry] {
        guard let out = shell("/bin/sh", ["-c", "ps -Aceo pid=,ppid=,pcpu=,pmem=,rss=,comm= -r"]) else { return [] }
        var entries: [ProcessMonitorEntry] = []

        for line in out.split(separator: "\n") {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 6 else { continue }
            guard let pid = Int(parts[0]), pid > 0 else { continue }
            let ppid = Int(parts[1]) ?? 0
            let cpu = Double(parts[2]) ?? 0
            let mem = Double(parts[3]) ?? 0
            let rssKB = UInt64(parts[4]) ?? 0
            let cmd = parts.dropFirst(5).joined(separator: " ")

            entries.append(ProcessMonitorEntry(
                pid: pid, ppid: ppid,
                name: String(cmd.split(separator: "/").last ?? Substring(cmd)),
                command: cmd,
                cpuPercent: cpu,
                memPercent: mem,
                memBytes: rssKB * 1024
            ))
        }
        return entries
    }

    // MARK: - Hardware Info (Mole system_profiler approach)

    private func collectHardwareInfo() {
        Task.detached(priority: .background) { [weak self] in
            guard let self else { return }
            var hw = HardwareInfoData()

            if let out = self.shell("/usr/bin/system_profiler", ["SPHardwareDataType"]) {
                for line in out.split(separator: "\n") {
                    let str = String(line).trimmingCharacters(in: .whitespaces)
                    let lower = str.lowercased()
                    if lower.contains("model name:") {
                        hw.modelName = str.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                    } else if lower.contains("chip:") || lower.contains("processor name:") {
                        if hw.chipName.isEmpty {
                            hw.chipName = str.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                        }
                    }
                }
            }

            if let out = self.shell("/usr/bin/sw_vers", ["-productVersion"]) {
                hw.osVersion = "macOS " + out.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            let fmt = ByteCountFormatter()
            fmt.countStyle = .memory
            hw.totalRAMFormatted = fmt.string(fromByteCount: Int64(ProcessInfo.processInfo.physicalMemory))

            await MainActor.run { self.hardware = hw }
        }
    }

    // MARK: - Kill Process

    func kill(pid: Int, completion: @escaping (Bool) -> Void) {
        Task.detached {
            let result = self.shell("/bin/kill", ["-9", String(pid)])
            await MainActor.run { completion(result != nil) }
        }
    }

    // MARK: - Shell Helper

    @discardableResult
    private func shell(_ command: String, _ args: [String]) -> String? {
        guard FileManager.default.fileExists(atPath: command) else { return nil }
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: command)
        proc.arguments = args
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()
        do {
            try proc.run()
            proc.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch { return nil }
    }

    // MARK: - Formatting Helpers

    static func formatSpeed(_ bytesPerSec: Double) -> String {
        if bytesPerSec >= 1_000_000 {
            return String(format: "%.1f MB/s", bytesPerSec / 1_000_000)
        } else if bytesPerSec >= 1000 {
            return String(format: "%.0f KB/s", bytesPerSec / 1000)
        } else {
            return String(format: "%.0f B/s", bytesPerSec)
        }
    }

    static func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
