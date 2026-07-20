import SwiftUI

struct nightshiftschedulerview: View {
    @State private var enabled = false
    @State private var message = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(
                title: "Night Shift & True Tone Scheduler",
                subtitle: "Configure a simple schedule preference and open display settings.",
                icon: "sun.horizon",
                refreshing: false,
                action: {}
            )
            Toggle("Night Shift schedule enabled", isOn: $enabled)
                .toggleStyle(.switch)
            Button("Open Display Settings") {
                guard let url = URL(string: "x-apple.systempreferences:com.apple.Displays-Settings.extension") else {
                    message = "Display settings are unavailable on this macOS version."
                    return
                }
                NSWorkspace.shared.open(url)
            }
            Text("True Tone and color temperature controls are managed by macOS display settings.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.caption)
            Spacer()
        }
        .padding(24)
    }
}
