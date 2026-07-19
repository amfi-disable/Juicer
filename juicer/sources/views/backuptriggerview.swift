import SwiftUI
import AppKit

struct backuptriggerview: View { @State private var source: URL?; @State private var destination: URL?; @State private var message = ""; var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "Automatic Backup Trigger", subtitle: "Run an explicit rsync backup from a selected folder to a destination.", icon: "externaldrive.badge.timemachine", refreshing: false, action: {}) ; HStack { Button("Choose Source…") { choose(source: true) }; Button("Choose Destination…") { choose(source: false) }; Button("Run Backup") { backup() }.buttonStyle(.borderedProminent) }; if let source { Text("Source: \(source.path)").font(.caption) }; if let destination { Text("Destination: \(destination.path)").font(.caption) }; Text(message).font(.caption); Spacer() }.padding(24) }
    private func choose(source: Bool) { let panel = NSOpenPanel(); panel.canChooseDirectories = true; panel.canChooseFiles = false; if panel.runModal() == .OK { if source { self.source = panel.url } else { destination = panel.url } } }
    private func backup() { guard let source, let destination else { message = "Choose source and destination."; return }; message = SystemMetricsSupport.run("/usr/bin/rsync", ["-a", "--delete", source.path + "/", destination.appendingPathComponent(source.lastPathComponent).path]) ?? "Backup failed." }
}
