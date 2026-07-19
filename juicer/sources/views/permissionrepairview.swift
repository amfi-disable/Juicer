import SwiftUI
import AppKit

struct permissionrepairview: View {
    @StateObject private var manager = PermissionRepairManager()
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            JuicerFeatureHeader(title: "File Permissions Repair", subtitle: "Inspect ownership and repair user-folder permissions safely.", icon: "lock.document", refreshing: manager.working, action: choose)
            HStack { Button("Choose Path…") { choose() }; Button("Inspect Home Folder") { manager.select(FileManager.default.homeDirectoryForCurrentUser) } }
            JuicerFeatureList(title: "Permission details") { Text(manager.snapshot.path.isEmpty ? "No path selected" : manager.snapshot.path).font(.system(.caption, design: .monospaced)); Text("Mode: \(manager.snapshot.mode)"); Text("Owner: \(manager.snapshot.owner) · Group: \(manager.snapshot.group)") }
            Text(manager.message).font(.caption).foregroundStyle(.secondary)
            Button("Repair Permissions") { manager.repair() }.buttonStyle(.borderedProminent).disabled(manager.selectedURL == nil || manager.working)
            Text("Home-folder repair uses diskutil and may request administrator access. Custom paths have their ACL entries removed with chmod -RN.").font(.caption).foregroundStyle(.secondary)
            Spacer()
        }.padding(24)
    }
    private func choose() { let panel = NSOpenPanel(); panel.canChooseFiles = true; panel.canChooseDirectories = true; if panel.runModal() == .OK, let url = panel.url { manager.select(url) } }
}
