import Foundation
import Combine

struct VPNProfile: Identifiable, Codable {
    let id = UUID()
    let name: String
    var connected: Bool
}

final class VPNProfileManager: ObservableObject {
    @Published var profiles: [VPNProfile] = []
    @Published var message = ""
    @Published var refreshing = false

    func refresh() {
        refreshing = true
        DispatchQueue.global().async {
            let output = SystemMetricsSupport.run("/usr/sbin/scutil", ["--nc", "list"]) ?? ""
            let profiles = output.split(separator: "\n").compactMap { line -> VPNProfile? in
                let text = String(line)
                guard let open = text.firstIndex(of: "\""), let close = text.lastIndex(of: "\""), close > open else { return nil }
                let name = String(text[text.index(after: open)..<close])
                return VPNProfile(name: name, connected: text.localizedCaseInsensitiveContains("connected"))
            }
            DispatchQueue.main.async {
                self.profiles = profiles
                self.refreshing = false
            }
        }
    }

    func toggle(_ profile: VPNProfile) {
        let action = profile.connected ? "stop" : "start"
        let result = SystemMetricsSupport.run("/usr/sbin/scutil", ["--nc", action, profile.name])
        message = result?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unable to change VPN state."
        refresh()
    }

    func exportProfiles() -> Data? {
        try? JSONEncoder().encode(profiles)
    }

    func importProfiles(_ data: Data) {
        guard let imported = try? JSONDecoder().decode([VPNProfile].self, from: data) else {
            message = "The selected file is not a valid Juicer VPN profile export."
            return
        }
        profiles = imported
        message = "Imported \(imported.count) profile descriptions. Configure them in macOS Network settings if they are not already installed."
    }
}
