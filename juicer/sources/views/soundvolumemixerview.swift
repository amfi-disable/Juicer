import SwiftUI

struct soundvolumemixerview: View { @State private var volume = 50.0; @State private var message = ""; var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "Sound Volume Mixer", subtitle: "Adjust the Mac's output volume with a quick control.", icon: "speaker.wave.2", refreshing: false, action: {}) ; Slider(value: $volume, in: 0...100) { Text("Output") } onEditingChanged: { editing in if !editing { apply() } }; Text("Output volume: \(Int(volume))%"); Button("Apply Volume") { apply() }.buttonStyle(.borderedProminent); Text("Per-app audio sessions require a dedicated Core Audio mixer and are not exposed by the basic system volume API.").font(.caption).foregroundStyle(.secondary); Text(message).font(.caption); Spacer() }.padding(24) }
    private func apply() { message = SystemMetricsSupport.run("/usr/bin/osascript", ["-e", "set volume output volume \(Int(volume))"]) ?? "Unable to set output volume." }
}
