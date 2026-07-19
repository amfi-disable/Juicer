import Foundation
import Combine

struct PowerSchedule: Identifiable {
    let id = UUID()
    let action: String
    let date: String
}

final class PowerScheduleManager: ObservableObject {
    @Published var schedules: [PowerSchedule] = []
    @Published var message = ""
    @Published var refreshing = false

    func refresh() {
        refreshing = true
        DispatchQueue.global().async {
            let output = SystemMetricsSupport.run("/usr/bin/pmset", ["-g", "sched"]) ?? ""
            let entries = output.split(separator: "\n").compactMap { line -> PowerSchedule? in
                let text = String(line).trimmingCharacters(in: .whitespaces)
                guard text.contains("wake") || text.contains("sleep") || text.contains("shutdown") || text.contains("restart") else { return nil }
                return PowerSchedule(action: text.components(separatedBy: " scheduled").first ?? "Scheduled event", date: text)
            }
            DispatchQueue.main.async {
                self.schedules = entries
                self.refreshing = false
            }
        }
    }

    func schedule(action: String, date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy HH:mm:ss"
        let result = SystemMetricsSupport.run("/usr/bin/pmset", ["schedule", action, formatter.string(from: date)])
        message = result?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? result!.trimmingCharacters(in: .whitespacesAndNewlines)
            : "Schedule request sent. Administrator privileges may be required."
        refresh()
    }
}

struct ThermalReading {
    var level = "Unknown"
    var detail = "Thermal pressure data is unavailable."
    var throttling = false
}

final class ThermalMonitorManager: ObservableObject {
    @Published var reading = ThermalReading()
    @Published var refreshing = false

    func refresh() {
        refreshing = true
        DispatchQueue.global().async {
            let thermal = SystemMetricsSupport.run("/usr/bin/pmset", ["-g", "therm"]) ?? ""
            let level = SystemMetricsSupport.run("/usr/sbin/sysctl", ["-n", "machdep.xcpm.cpu_thermal_level"])?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "0"
            let throttling = thermal.localizedCaseInsensitiveContains("thrott") || (Int(level) ?? 0) > 0
            let detail = thermal.split(separator: "\n").first.map(String.init) ?? "Thermal pressure data is unavailable."
            DispatchQueue.main.async {
                self.reading = ThermalReading(level: throttling ? "Throttling detected" : "Nominal", detail: "CPU thermal level: \(level). \(detail)", throttling: throttling)
                self.refreshing = false
            }
        }
    }
}

struct FanReading: Identifiable {
    let id = UUID()
    let text: String
}

final class FanControllerManager: ObservableObject {
    @Published var fans: [FanReading] = []
    @Published var supported = false
    @Published var message = ""
    @Published var refreshing = false

    private var smcPath: String? {
        ["/usr/local/bin/smc", "/opt/homebrew/bin/smc"].first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    func refresh() {
        refreshing = true
        DispatchQueue.global().async {
            let path = self.smcPath
            let output = path.flatMap { SystemMetricsSupport.run($0, ["-f"]) } ?? ""
            DispatchQueue.main.async {
                self.supported = path != nil
                self.fans = output.split(separator: "\n").map { FanReading(text: String($0)) }
                self.message = path == nil ? "No compatible SMC controller was found. Fan control is hardware-specific." : ""
                self.refreshing = false
            }
        }
    }

    func applyMinimumRPM(_ rpm: Int) {
        guard let path = smcPath else { return }
        let hex = String(format: "%04x", max(0, min(65535, rpm)))
        _ = SystemMetricsSupport.run(path, ["-k", "F0Mn", "-w", hex])
        message = "Requested a minimum fan speed of \(rpm) RPM."
        refresh()
    }
}

struct MemoryReading {
    var used = UInt64(0)
    var free = UInt64(0)
    var purgeable = UInt64(0)
    var status = "Ready"
}

final class MemoryPurgeManager: ObservableObject {
    @Published var reading = MemoryReading()
    @Published var purging = false

    func refresh() {
        reading = parseMemory(status: reading.status)
    }

    func purge() {
        purging = true
        let before = parseMemory(status: "Before purge")
        DispatchQueue.global().async {
            let output = SystemMetricsSupport.run("/usr/bin/purge")
            let succeeded = output != nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.reading = self.parseMemory(status: succeeded ? "Purge completed" : "Purge failed; administrator privileges may be required")
                self.reading.used = before.used
                self.purging = false
            }
        }
    }

    private func parseMemory(status: String) -> MemoryReading {
        let output = SystemMetricsSupport.run("/usr/bin/vm_stat") ?? ""
        let pageSize = UInt64(SystemMetricsSupport.run("/usr/bin/sysctl", ["-n", "vm.pagesize"])?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "4096") ?? 4096
        func pages(_ label: String) -> UInt64 {
            guard let line = output.split(separator: "\n").first(where: { $0.hasPrefix(label) }) else { return 0 }
            return UInt64(line.filter { $0.isNumber }) ?? 0
        }
        let free = pages("Pages free") * pageSize
        let inactive = pages("Pages inactive") * pageSize
        let purgeable = pages("Pages purgeable") * pageSize
        let total = ProcessInfo.processInfo.physicalMemory
        return MemoryReading(used: total > free + inactive ? total - free - inactive : 0, free: free, purgeable: purgeable, status: status)
    }
}
