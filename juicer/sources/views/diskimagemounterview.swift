import SwiftUI
import AppKit

struct diskimagemounterview: View { @State private var image: URL?; @State private var message = ""; var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "Automatic Disk Image Mounter", subtitle: "Select a DMG or ISO and mount it with hdiutil.", icon: "externaldrive.badge.plus", refreshing: false, action: {}) ; HStack { Button("Choose Image…") { choose() }; Button("Mount") { mount() }.buttonStyle(.borderedProminent).disabled(image == nil) }; if let image { Text(image.path).font(.caption).foregroundStyle(.secondary) }; Text(message).font(.caption); Spacer() }.padding(24) }
    private func choose() { let panel = NSOpenPanel(); panel.allowedFileTypes = ["dmg", "iso", "sparsebundle"]; if panel.runModal() == .OK { image = panel.url } }
    private func mount() { guard let image else { return }; message = SystemMetricsSupport.run("/usr/bin/hdiutil", ["attach", image.path]) ?? "Unable to mount disk image." }
}
