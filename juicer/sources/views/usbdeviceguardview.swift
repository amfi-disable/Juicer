import SwiftUI

struct usbdeviceguardview: View {
    @State private var devices: [String] = []
    @State private var whitelist = ""
    @State private var message = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "USB Device Guard", subtitle: "Inventory connected USB devices and compare them with a local whitelist.", icon: "externaldrive.connected.to.line.below", refreshing: false, action: scan)
            HStack { TextField("Whitelisted device names, comma-separated", text: $whitelist); Button("Scan") { scan() }.buttonStyle(.borderedProminent) }
            Text("Juicer reports unknown devices; blocking hardware is left to macOS security policy.").font(.caption).foregroundStyle(.secondary)
            List(devices, id: \.self) { device in HStack { Image(systemName: whitelist.lowercased().contains(device.lowercased()) ? "checkmark.shield" : "exclamationmark.shield"); Text(device) } }.listStyle(.inset)
            if !message.isEmpty { Text(message).font(.caption).foregroundStyle(.secondary) }
        }.padding(24).onAppear(perform: scan)
    }
    private func scan() { DispatchQueue.global().async { let output = SystemMetricsSupport.run("/usr/sbin/system_profiler", ["SPUSBDataType", "-detailLevel", "mini"]) ?? "Unable to inspect USB devices."; let lines = output.components(separatedBy: .newlines).filter { $0.hasSuffix(":") && !$0.contains("USB:") }.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: ":")) }; DispatchQueue.main.async { devices = lines; message = "Found \(lines.count) USB device(s)." } } }
}
