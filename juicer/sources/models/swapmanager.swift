import Foundation
import Combine

struct SwapReading {
    var total: UInt64 = 0
    var used: UInt64 = 0
    var free: UInt64 = 0
    var enabled = true
    var detail = ""
}

final class SwapManager: ObservableObject {
    @Published var reading = SwapReading()
    @Published var refreshing = false
    @Published var changing = false
    @Published var message = ""

    func refresh() {
        refreshing = true
        DispatchQueue.global().async {
            let usage = SystemMetricsSupport.run("/usr/sbin/sysctl", ["vm.swapusage"]) ?? ""
            let values = usage.split(whereSeparator: { $0 == " " || $0 == "\t" }).reduce(into: [String: UInt64]()) { result, token in
                let parts = token.split(separator: "=")
                guard parts.count == 2 else { return }
                result[String(parts[0])] = Self.parseSize(String(parts[1]))
            }
            let enabled = !(SystemMetricsSupport.run("/bin/launchctl", ["print-disabled", "system"]) ?? "").contains("com.apple.dynamic_pager = true")
            DispatchQueue.main.async {
                self.reading = SwapReading(total: values["total"] ?? 0, used: values["used"] ?? 0, free: values["free"] ?? 0, enabled: enabled, detail: usage.trimmingCharacters(in: .whitespacesAndNewlines))
                self.refreshing = false
            }
        }
    }

    func setEnabled(_ enabled: Bool) {
        changing = true
        let action = enabled ? "load" : "unload"
        let script = "/bin/launchctl \(action) -w /System/Library/LaunchDaemons/com.apple.dynamic_pager.plist"
        let escaped = script.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        let result = SystemMetricsSupport.run("/usr/bin/osascript", ["-e", "do shell script \"\(escaped)\" with administrator privileges"])
        message = result == nil ? "Unable to change swap. Administrator approval may have been cancelled." : "Swap configuration request sent."
        changing = false
        refresh()
    }

    private static func parseSize(_ value: String) -> UInt64 {
        let number = Double(value.filter { $0.isNumber || $0 == "." }) ?? 0
        if value.contains("G") { return UInt64(number * 1_073_741_824) }
        if value.contains("M") { return UInt64(number * 1_048_576) }
        if value.contains("K") { return UInt64(number * 1_024) }
        return UInt64(number)
    }
}
