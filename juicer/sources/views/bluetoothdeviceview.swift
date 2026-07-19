import SwiftUI

struct bluetoothdeviceview: View {
    @StateObject private var manager = BluetoothDeviceManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            JuicerFeatureHeader(title: "Bluetooth Device Manager", subtitle: "Pair, connect, and monitor preferred Bluetooth devices.", icon: "dot.radiowaves.left.and.right", refreshing: manager.refreshing, action: manager.refresh)
            HStack {
                TextField("Bluetooth address to pair", text: $manager.addressToPair).textFieldStyle(.roundedBorder)
                Button("Pair") { manager.pair() }.buttonStyle(.borderedProminent).disabled(!manager.supported)
            }
            if !manager.message.isEmpty { Text(manager.message).font(.caption).foregroundStyle(.secondary) }
            List(manager.devices) { device in
                HStack {
                    Image(systemName: device.connected ? "dot.radiowaves.left.and.right" : "circle").foregroundStyle(device.connected ? .green : .secondary)
                    VStack(alignment: .leading) { Text(device.name); Text(device.address).font(.caption).foregroundStyle(.secondary) }
                    Spacer()
                    if let battery = device.battery { Text("\(battery)%").font(.caption).monospacedDigit() }
                    Button(device.connected ? "Disconnect" : "Connect") { manager.toggle(device) }.buttonStyle(.bordered).disabled(!manager.supported)
                    Toggle("Preferred", isOn: Binding(get: { device.preferred }, set: { manager.setPreferred(device, preferred: $0) })).labelsHidden()
                }
            }
            .listStyle(.inset)
        }
        .padding(24)
        .onAppear { manager.refresh() }
    }
}
