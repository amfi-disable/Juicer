import Foundation
import Combine

struct PermissionSnapshot {
    var path = ""
    var mode = ""
    var owner = ""
    var group = ""
}

final class PermissionRepairManager: ObservableObject {
    @Published var selectedURL: URL?
    @Published var snapshot = PermissionSnapshot()
    @Published var message = "Choose a file or folder to inspect."
    @Published var working = false

    func select(_ url: URL) {
        selectedURL = url
        let output = SystemMetricsSupport.run("/usr/bin/stat", ["-f", "%Sp|%Su|%Sg", url.path]) ?? ""
        let values = output.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "|").map(String.init)
        snapshot = PermissionSnapshot(path: url.path, mode: values.first ?? "unknown", owner: values.count > 1 ? values[1] : "unknown", group: values.count > 2 ? values[2] : "unknown")
        message = "Permissions inspected."
    }

    func repair() {
        guard let url = selectedURL else { return }
        working = true
        let isHome = url.standardizedFileURL == FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL
        let command: String
        let arguments: [String]
        if isHome {
            command = "/usr/sbin/diskutil"; arguments = ["resetUserPermissions", "/", String(getuid())]
        } else {
            command = "/bin/chmod"; arguments = ["-RN", url.path]
        }
        DispatchQueue.global().async { let output = SystemMetricsSupport.run(command, arguments) ?? "Permission repair failed or requires administrator access."; DispatchQueue.main.async { self.message = output.split(separator: "\n").last.map(String.init) ?? "Permission repair completed."; self.working = false; self.select(url) } }
    }
}
