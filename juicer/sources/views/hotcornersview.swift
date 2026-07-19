import SwiftUI

struct hotcornersview: View {
    @State private var corners = ["Top Left": "Mission Control", "Top Right": "Desktop", "Bottom Left": "Lock Screen", "Bottom Right": "Quick Note"]
    private let actions = ["None", "Mission Control", "Application Windows", "Desktop", "Start Screen Saver", "Disable Screen Saver", "Display Sleep", "Launchpad", "Notification Center", "Lock Screen", "Quick Note"]
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Hot Corners Configurator", subtitle: "Assign built-in macOS actions to each screen corner.", icon: "rectangle.4.connected.lines", refreshing: false, action: {})
            ForEach(["Top Left", "Top Right", "Bottom Left", "Bottom Right"], id: \.self) { corner in HStack { Text(corner).frame(width: 120, alignment: .leading); Picker(corner, selection: Binding(get: { corners[corner] ?? "None" }, set: { corners[corner] = $0 })) { ForEach(actions, id: \.self) { Text($0).tag($0) } }.labelsHidden(); Spacer() } }
            Button("Apply Hot Corners") { apply() }.buttonStyle(.borderedProminent)
            Text("Applying restarts the Dock so macOS can reload the corner settings.").font(.caption).foregroundStyle(.secondary)
            Spacer()
        }.padding(24)
    }
    private func apply() { let keys = ["Top Left": "wvous-tl-corner", "Top Right": "wvous-tr-corner", "Bottom Left": "wvous-bl-corner", "Bottom Right": "wvous-br-corner"]; let values = ["None": "0", "Mission Control": "2", "Application Windows": "3", "Desktop": "4", "Start Screen Saver": "5", "Disable Screen Saver": "6", "Display Sleep": "10", "Launchpad": "11", "Notification Center": "12", "Lock Screen": "13", "Quick Note": "14"]; for (corner, key) in keys { _ = SystemMetricsSupport.run("/usr/bin/defaults", ["write", "com.apple.dock", key, "-int", values[corners[corner] ?? "None"] ?? "0"]) }; _ = SystemMetricsSupport.run("/usr/bin/killall", ["Dock"]) }
}
