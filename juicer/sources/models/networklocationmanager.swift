import Foundation
import Combine

struct NetworkLocation: Identifiable {
    let id = UUID()
    let name: String
    var current: Bool
}

final class NetworkLocationManager: ObservableObject {
    @Published var locations: [NetworkLocation] = []
    @Published var newName = ""
    @Published var message = ""
    @Published var refreshing = false

    func refresh() {
        refreshing = true
        DispatchQueue.global().async {
            let output = SystemMetricsSupport.run("/usr/sbin/networksetup", ["-listlocations"]) ?? ""
            let current = SystemMetricsSupport.run("/usr/sbin/networksetup", ["-getcurrentlocation"])?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let names = output.split(separator: "\n").dropFirst().map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            DispatchQueue.main.async {
                self.locations = names.map { NetworkLocation(name: $0, current: $0 == current) }
                self.refreshing = false
            }
        }
    }

    func switchTo(_ location: NetworkLocation) {
        message = SystemMetricsSupport.run("/usr/sbin/networksetup", ["-switchtolocation", location.name])?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Location switch failed."
        refresh()
    }

    func create() {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { message = "Enter a location name first."; return }
        message = SystemMetricsSupport.run("/usr/sbin/networksetup", ["-createlocation", name, "populate"])?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Location creation failed."
        newName = ""
        refresh()
    }

    func delete(_ location: NetworkLocation) {
        guard !location.current else { message = "Switch to another location before deleting the current one."; return }
        message = SystemMetricsSupport.run("/usr/sbin/networksetup", ["-deletelocation", location.name])?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Location deletion failed."
        refresh()
    }
}
