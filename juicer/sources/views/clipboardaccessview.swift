import SwiftUI
import AppKit

struct clipboardaccessview: View {
    @State private var changeCount = NSPasteboard.general.changeCount
    @State private var lastChange = "No clipboard change detected"
    @State private var timer: Timer?
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Clipboard Access Monitor", subtitle: "Watch for clipboard changes without storing clipboard contents.", icon: "doc.on.clipboard", refreshing: false, action: check)
            HStack { Image(systemName: "eye"); Text(lastChange); Spacer(); Button("Check Now") { check() } }
            Text("macOS does not expose a reliable per-app clipboard-read audit to third-party utilities. This monitor deliberately records no clipboard data.").font(.caption).foregroundStyle(.secondary)
            Spacer()
        }.padding(24).onAppear { timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in check() } }.onDisappear { timer?.invalidate() }
    }
    private func check() { let current = NSPasteboard.general.changeCount; if current != changeCount { changeCount = current; lastChange = "Clipboard changed at \(Date().formatted(date: .omitted, time: .standard))" } }
}
