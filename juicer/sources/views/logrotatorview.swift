import SwiftUI
import AppKit

struct logrotatorview: View { @State private var file: URL?; @State private var message = ""; var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "Log File Rotator", subtitle: "Compress an archived log file with explicit user selection.", icon: "doc.zipper", refreshing: false, action: {}) ; HStack { Button("Choose Log…") { choose() }; Button("Compress") { rotate() }.buttonStyle(.borderedProminent).disabled(file == nil) }; if let file { Text(file.path).font(.caption).foregroundStyle(.secondary) }; Text(message).font(.caption); Spacer() }.padding(24) }
    private func choose() { let panel = NSOpenPanel(); if panel.runModal() == .OK { file = panel.url } }
    private func rotate() { guard let file else { return }; let output = SystemMetricsSupport.run("/usr/bin/gzip", [file.path]); message = output == nil ? "Compression failed." : "Compressed selected log." }
}
