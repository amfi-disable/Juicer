import SwiftUI
import AppKit

struct quarantinedfilesview: View {
    @State private var files: [URL] = []
    @State private var message = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Quarantined-file Scanner", subtitle: "Find files carrying macOS quarantine metadata and review or strip it.", icon: "shield.lefthalf.filled", refreshing: false, action: {})
            HStack { Button("Scan Folder…") { scan() }; Spacer(); Button("Strip Quarantine") { strip() }.buttonStyle(.borderedProminent).disabled(files.isEmpty) }
            if !message.isEmpty { Text(message).font(.caption).foregroundStyle(.secondary) }
            List(files, id: \.self) { Label($0.path, systemImage: "exclamationmark.shield").lineLimit(1).truncationMode(.middle) }.listStyle(.inset)
        }.padding(24)
    }
    private func scan() { let panel = NSOpenPanel(); panel.canChooseDirectories = true; panel.canChooseFiles = false; guard panel.runModal() == .OK, let root = panel.url else { return }; DispatchQueue.global().async { let urls = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)?.compactMap { $0 as? URL }.filter { SystemMetricsSupport.run("/usr/bin/xattr", ["-p", "com.apple.quarantine", $0.path]) != nil } ?? []; DispatchQueue.main.async { files = urls; message = "Found \(urls.count) quarantined file(s)." } } }
    private func strip() { let selected = files; DispatchQueue.global().async { for url in selected { _ = SystemMetricsSupport.run("/usr/bin/xattr", ["-d", "com.apple.quarantine", url.path]) }; DispatchQueue.main.async { files = []; message = "Removed quarantine metadata from selected entries where permitted." } } }
}
