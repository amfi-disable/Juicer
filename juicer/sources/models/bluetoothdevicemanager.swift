import Foundation
import Combine

struct BluetoothDevice: Identifiable {
    let id = UUID()
    let address: String
    let name: String
    var connected: Bool
    var battery: Int?
    var preferred: Bool
}

final class BluetoothDeviceManager: ObservableObject {
    @Published var devices: [BluetoothDevice] = []
    @Published var addressToPair = ""
    @Published var message = ""
    @Published var refreshing = false
    @Published var supported = false

    private var utilityPath: String? {
        ["/opt/homebrew/bin/blueutil", "/usr/local/bin/blueutil"].first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    func refresh() {
        refreshing = true
        DispatchQueue.global().async {
            let path = self.utilityPath
            let output = path.flatMap { SystemMetricsSupport.run($0, ["--paired"]) } ?? ""
            let devices = output.split(separator: "\n").compactMap { self.parse(String($0)) }
            DispatchQueue.main.async {
                self.supported = path != nil
                self.devices = devices
                self.refreshing = false
                if path == nil { self.message = "Install blueutil to pair and control Bluetooth devices from Juicer." }
            }
        }
    }

    func toggle(_ device: BluetoothDevice) {
        guard let path = utilityPath else { return }
        let action = device.connected ? "--disconnect" : "--connect"
        message = SystemMetricsSupport.run(path, [action, device.address])?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Bluetooth action failed."
        refresh()
    }

    func pair() {
        guard let path = utilityPath, !addressToPair.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { message = "Enter a Bluetooth address and install blueutil first."; return }
        message = SystemMetricsSupport.run(path, ["--pair", addressToPair.trimmingCharacters(in: .whitespacesAndNewlines)])?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Pairing failed."
        addressToPair = ""
        refresh()
    }

    func setPreferred(_ device: BluetoothDevice, preferred: Bool) {
        UserDefaults.standard.set(preferred, forKey: "juicer.bluetooth.preferred.\(device.address)")
        refresh()
    }

    private func parse(_ line: String) -> BluetoothDevice? {
        let fields = line.split(separator: ",").reduce(into: [String: String]()) { result, field in
            let parts = field.split(separator: ":", maxSplits: 1).map(String.init)
            if parts.count == 2 { result[parts[0].trimmingCharacters(in: .whitespaces)] = parts[1].trimmingCharacters(in: .whitespaces) }
        }
        guard let address = fields["address"] else { return nil }
        let battery = fields["battery"]?.filter { $0.isNumber }.flatMap(Int.init)
        let preferred = UserDefaults.standard.bool(forKey: "juicer.bluetooth.preferred.\(address)")
        return BluetoothDevice(address: address, name: fields["name"] ?? address, connected: fields["connected"] == "1", battery: battery, preferred: preferred)
    }
}
