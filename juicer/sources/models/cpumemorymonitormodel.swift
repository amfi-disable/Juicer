import Foundation

struct CPUMemorySample: Identifiable {
    let id = UUID()
    let date: Date
    let cpuPercent: Double
    let memoryPercent: Double
}

final class CPUMemoryMonitorManager: ObservableObject {
    @Published var cpuPercent = 0.0
    @Published var memoryUsedBytes: UInt64 = 0
    @Published var memoryTotalBytes: UInt64 = ProcessInfo.processInfo.physicalMemory
    @Published var memoryPressure = "normal"
    @Published var swapUsedBytes: UInt64 = 0
    @Published var loadAverages: [Double] = [0, 0, 0]
    @Published var samples: [CPUMemorySample] = []
    @Published var isRefreshing = false

    private var timer: Timer?

    func start() { refresh(); timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in self?.refresh() } }
    func stop() { timer?.invalidate(); timer = nil }

    func refresh() {
        isRefreshing = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let cpu = Self.readCPU()
            let memory = Self.readMemory()
            DispatchQueue.main.async {
                guard let self else { return }
                self.cpuPercent = cpu.usage
                self.loadAverages = cpu.loads
                self.memoryUsedBytes = memory.used
                self.memoryTotalBytes = memory.total
                self.memoryPressure = memory.pressure
                self.swapUsedBytes = memory.swap
                let sample = CPUMemorySample(date: Date(), cpuPercent: cpu.usage, memoryPercent: memory.total > 0 ? Double(memory.used) / Double(memory.total) * 100 : 0)
                self.samples = Array((self.samples + [sample]).suffix(60))
                self.isRefreshing = false
            }
        }
    }

    private static func readCPU() -> (usage: Double, loads: [Double]) {
        let cores = Double(max(1, ProcessInfo.processInfo.processorCount))
        let total = SystemMetricsSupport.run("/bin/ps", ["-Aceo", "pcpu"])?.split(separator: "\n").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }.reduce(0, +) ?? 0
        let usage = min(100, total / cores)
        let loadText = SystemMetricsSupport.run("/usr/sbin/sysctl", ["-n", "vm.loadavg"]) ?? ""
        let loads = loadText.replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: "").split(whereSeparator: { $0 == " " || $0 == "\t" }).compactMap { Double($0) }
        return (usage, Array(loads.prefix(3)) + Array(repeating: 0, count: max(0, 3 - loads.count)))
    }

    private static func readMemory() -> (used: UInt64, total: UInt64, pressure: String, swap: UInt64) {
        let total = ProcessInfo.processInfo.physicalMemory
        let output = SystemMetricsSupport.run("/usr/bin/vm_stat") ?? ""
        var pageSize: UInt64 = 4096
        var pages: [String: UInt64] = [:]
        for line in output.split(separator: "\n") {
            let text = String(line)
            if text.contains("page size of "), let value = text.components(separatedBy: "page size of ").last?.split(separator: " ").first, let parsed = UInt64(value) { pageSize = parsed }
            guard let colon = text.firstIndex(of: ":") else { continue }
            let key = String(text[..<colon])
            let number = text[text.index(after: colon)...].filter { $0.isNumber }
            if let parsed = UInt64(number) { pages[key] = parsed }
        }
        let usedPages = (pages["Pages active"] ?? 0) + (pages["Pages wired down"] ?? 0) + (pages["Pages occupied by compressor"] ?? 0)
        let used = min(total, usedPages * pageSize)
        let pressureText = (SystemMetricsSupport.run("/usr/bin/memory_pressure") ?? "").lowercased()
        let pressure = pressureText.contains("critical") ? "critical" : (pressureText.contains("warn") ? "warn" : "normal")
        let swapText = SystemMetricsSupport.run("/usr/sbin/sysctl", ["-n", "vm.swapusage"]) ?? ""
        let swap = swapText.components(separatedBy: "used =").dropFirst().first?.split(separator: " ").first.flatMap { Double($0.replacingOccurrences(of: "M", with: "")) }.map { UInt64($0 * 1024 * 1024) } ?? 0
        return (used, total, pressure, swap)
    }
}
