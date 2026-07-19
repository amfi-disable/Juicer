import Foundation
import Combine

struct GPUReading { var name = "Unknown GPU"; var usage = 0.0; var memory = "Unavailable" }
final class GPUUtilizationMonitorManager: ObservableObject { @Published var reading = GPUReading(); @Published var refreshing = false
    func refresh() { refreshing = true; DispatchQueue.global().async { let text = SystemMetricsSupport.run("/usr/sbin/system_profiler", ["SPDisplaysDataType"]) ?? ""; let name = text.split(separator: "\n").first.map(String.init) ?? "Unknown GPU"; let usage = Double((SystemMetricsSupport.run("/usr/sbin/ioreg", ["-l", "-w0", "-c", "AGCInfo"]) ?? "").components(separatedBy: "Device Utilization = ").dropFirst().first?.split(separator: ",").first ?? "") ?? 0; DispatchQueue.main.async { self.reading = GPUReading(name: name.trimmingCharacters(in: .whitespaces), usage: min(100, usage), memory: "Reported by macOS when available"); self.refreshing = false } } }
}

struct DiskIOReading: Identifiable { let id = UUID(); let name: String; let readRate: Double; let writeRate: Double }
final class DiskIOMonitorManager: ObservableObject { @Published var readings: [DiskIOReading] = []; @Published var refreshing = false; private var previous: [String: (UInt64, UInt64, Date)] = [:]
    func refresh() { refreshing = true; DispatchQueue.global().async { let text = SystemMetricsSupport.run("/usr/sbin/ioreg", ["-c", "IOBlockStorageDriver", "-l"]) ?? ""; let now = Date(); var result: [DiskIOReading] = []; for line in text.split(separator: "\n") where line.contains("Statistics") { let nums = line.filter { $0.isNumber || $0 == " " }.split(separator: " ").compactMap { UInt64($0) }; if nums.count >= 2 { let key = "disk\(result.count)"; let old = self.previous[key]; let dt = max(1, now.timeIntervalSince(old?.2 ?? now)); var read = 0.0; var write = 0.0; if let old { read = Double(nums[0] &- old.0) / dt; write = Double(nums[1] &- old.1) / dt }; self.previous[key] = (nums[0], nums[1], now); result.append(DiskIOReading(name: key, readRate: read, writeRate: write)) } }; DispatchQueue.main.async { self.readings = result; self.refreshing = false } } }
}

struct NetworkReading: Identifiable { let id = UUID(); let interface: String; let download: Double; let upload: Double }
final class NetworkTrafficMonitorManager: ObservableObject { @Published var readings: [NetworkReading] = []; @Published var connections = 0; @Published var refreshing = false; private var previous: [String: (UInt64, UInt64, Date)] = [:]
    func refresh() { refreshing = true; DispatchQueue.global().async { let text = SystemMetricsSupport.run("/usr/sbin/netstat", ["-ib"]) ?? ""; let now = Date(); var result: [NetworkReading] = []; for line in text.split(separator: "\n") { let p = line.split(whereSeparator: { $0 == " " || $0 == "\t" }); guard p.count > 9, p[0] != "Name", let rx = UInt64(p[6]), let tx = UInt64(p[9]) else { continue }; let key = String(p[0]); let old = self.previous[key]; let dt = max(1, now.timeIntervalSince(old?.2 ?? now)); var download = 0.0; var upload = 0.0; if let old { download = Double(rx &- old.0) / dt; upload = Double(tx &- old.1) / dt }; result.append(NetworkReading(interface: key, download: download, upload: upload)); self.previous[key] = (rx, tx, now) }; let count = (SystemMetricsSupport.run("/usr/sbin/lsof", ["-i", "-n", "-P"]) ?? "").split(separator: "\n").count; DispatchQueue.main.async { self.readings = result; self.connections = max(0, count - 1); self.refreshing = false } } }
}

struct BatteryReading { var present = false; var cycleCount = 0; var capacity = 0.0; var temperature = 0.0; var charging = false }
final class BatteryHealthManager: ObservableObject { @Published var reading = BatteryReading(); @Published var refreshing = false
    func refresh() { refreshing = true; DispatchQueue.global().async { let text = SystemMetricsSupport.run("/usr/sbin/ioreg", ["-rc", "AppleSmartBattery", "-a"]) ?? ""; func number(_ key: String) -> Double { Double(text.components(separatedBy: "\"\(key)\" = ").dropFirst().first?.split(separator: "\n").first?.filter { $0.isNumber || $0 == "." } ?? "") ?? 0 }; let design = number("DesignCapacity"); let max = number("MaxCapacity"); DispatchQueue.main.async { self.reading = BatteryReading(present: text.contains("AppleSmartBattery"), cycleCount: Int(number("CycleCount")), capacity: design > 0 ? max / design * 100 : 0, temperature: number("Temperature") / 100, charging: text.contains("IsCharging") && text.contains("Yes")); self.refreshing = false } } }
}

struct ManagedItem: Identifiable { let id = UUID(); let name: String; let path: String; var enabled: Bool }
final class StartupItemManager: ObservableObject { @Published var items: [ManagedItem] = []; @Published var refreshing = false
    func refresh() { refreshing = true; DispatchQueue.global().async { let dirs = ["\(NSHomeDirectory())/Library/LaunchAgents", "/Library/LaunchAgents", "/Library/LaunchDaemons"]; let files = dirs.flatMap { (try? FileManager.default.contentsOfDirectory(atPath: $0)) ?? [] }.filter { $0.hasSuffix(".plist") }; let result = files.map { ManagedItem(name: ($0 as NSString).deletingPathExtension, path: $0, enabled: true) }; DispatchQueue.main.async { self.items = result; self.refreshing = false } } }
    func toggle(_ item: ManagedItem) { if let i = items.firstIndex(where: { $0.id == item.id }) { items[i].enabled.toggle() } }
}

struct LoginItemDelay: Identifiable { let id = UUID(); var name: String; var seconds: Double }
final class LoginItemDelayManager: ObservableObject { @Published var delays: [LoginItemDelay] = []; func add() { delays.append(LoginItemDelay(name: "New Login Item", seconds: 5)) }; func remove(_ item: LoginItemDelay) { delays.removeAll { $0.id == item.id } } }

struct KillableProcess: Identifiable { let id = UUID(); let pid: Int; let name: String; let cpu: Double; let memory: Double }
final class ProcessKillerManager: ObservableObject { @Published var processes: [KillableProcess] = []; @Published var query = ""; func refresh() { let text = SystemMetricsSupport.run("/bin/ps", ["-axo", "pid,pcpu,pmem,comm"]) ?? ""; processes = text.split(separator: "\n").dropFirst().compactMap { let p = $0.split(maxSplits: 3, whereSeparator: { $0 == " " }); guard p.count == 4, let pid = Int(p[0]), let cpu = Double(p[1]), let mem = Double(p[2]) else { return nil }; return KillableProcess(pid: pid, name: String(p[3]), cpu: cpu, memory: mem) }.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }.prefix(100).map { $0 } }; func kill(_ process: KillableProcess, force: Bool = false) { _ = SystemMetricsSupport.run("/bin/kill", [force ? "-9" : "-TERM", String(process.pid)]); refresh() } }

struct SystemLogEntry: Identifiable { let id = UUID(); let text: String }
final class SystemLogManager: ObservableObject { @Published var entries: [SystemLogEntry] = []; @Published var query = ""; func refresh() { let text = SystemMetricsSupport.run("/usr/bin/log", ["show", "--last", "1h", "--style", "compact"]) ?? ""; entries = text.split(separator: "\n").map { SystemLogEntry(text: String($0)) }.filter { query.isEmpty || $0.text.localizedCaseInsensitiveContains(query) }.suffix(500).map { $0 } } }

struct KernelExtension: Identifiable { let id = UUID(); let name: String; let version: String }
final class KextManager: ObservableObject { @Published var extensions: [KernelExtension] = []; @Published var supported = false; func refresh() { let text = SystemMetricsSupport.run("/usr/bin/kmutil", ["showloaded"]) ?? ""; supported = !text.isEmpty; extensions = text.split(separator: "\n").dropFirst().compactMap { line in let p = line.split(whereSeparator: { $0 == " " || $0 == "\t" }); guard let name = p.last else { return nil }; return KernelExtension(name: String(name), version: "loaded") } } }
