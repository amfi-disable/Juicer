import SwiftUI
import CoreGraphics

struct screenrecordingdetectorview: View {
    @State private var status = "Unknown"
    @State private var timer: Timer?
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Screen Recording Detector", subtitle: "Monitor screen-capture permission state and macOS recording indicators.", icon: "record.circle", refreshing: false, action: refresh)
            HStack { Image(systemName: status == "Permission available" ? "checkmark.circle.fill" : "exclamationmark.triangle.fill").foregroundStyle(status == "Permission available" ? .green : .orange); Text(status).font(.title3); Spacer(); Button("Refresh") { refresh() } }
            Text("macOS owns the active-session indicator. Juicer does not capture or store screen contents.").font(.caption).foregroundStyle(.secondary)
            Spacer()
        }.padding(24).onAppear { refresh(); timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in refresh() } }.onDisappear { timer?.invalidate() }
    }
    private func refresh() { status = CGPreflightScreenCaptureAccess() ? "Permission available" : "No screen-recording permission granted" }
}
