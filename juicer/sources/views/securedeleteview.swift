import SwiftUI
import AppKit

struct securedeleteview: View {
    @State private var files: [URL] = []
    @State private var passes = 3
    @State private var message = ""
    @State private var confirm = false
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Secure Delete", subtitle: "Overwrite selected files before removing them from the filesystem.", icon: "trash.slash", refreshing: false, action: {})
            HStack { Button("Choose Files…") { choose() }; Picker("Passes", selection: $passes) { Text("1 pass").tag(1); Text("3 passes").tag(3); Text("7 passes").tag(7) }.frame(width: 140); Spacer(); Button("Secure Delete") { confirm = true }.buttonStyle(.borderedProminent).disabled(files.isEmpty) }
            Text("SSD and APFS wear-leveling can prevent guaranteed physical erasure. This removes the selected filesystem entries after overwriting.").font(.caption).foregroundStyle(.orange)
            if !message.isEmpty { Text(message).font(.caption).foregroundStyle(.secondary) }
            List(files, id: \.self) { Text($0.path).lineLimit(1).truncationMode(.middle) }.listStyle(.inset)
        }.padding(24).alert("Securely delete selected files?", isPresented: $confirm) { Button("Cancel", role: .cancel) {}; Button("Delete", role: .destructive) { erase() } } message: { Text("This cannot be undone.") }
    }
    private func choose() { let panel = NSOpenPanel(); panel.allowsMultipleSelection = true; if panel.runModal() == .OK { files = panel.urls } }
    private func erase() { let selected = files; let count = passes; DispatchQueue.global().async { var removed = 0; for url in selected { do { let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0; let chunk = Data(repeating: 0, count: 1_048_576); let handle = try FileHandle(forWritingTo: url); for _ in 0..<count { try handle.seek(toOffset: 0); var remaining = UInt64(size); while remaining > 0 { let amount = min(remaining, UInt64(chunk.count)); try handle.write(contentsOf: chunk.prefix(Int(amount))); remaining -= amount } }; try handle.close(); try FileManager.default.removeItem(at: url); removed += 1 } catch {} }; DispatchQueue.main.async { files = []; message = "Securely removed \(removed) of \(selected.count) file(s)." } } }
}
