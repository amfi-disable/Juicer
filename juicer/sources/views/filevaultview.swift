import SwiftUI

struct filevaultview: View {
    @State private var status = "Not checked"
    @State private var details = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "FileVault Status", subtitle: "Review encryption state and recovery-key guidance without exposing secrets.", icon: "lock.shield", refreshing: false, action: refresh)
            HStack { Text(status).font(.title3); Spacer(); Button("Refresh") { refresh() }.buttonStyle(.borderedProminent) }
            Text("For security, Juicer never displays or stores a recovery key. Use System Settings to rotate or escrow one.").font(.caption).foregroundStyle(.secondary)
            if !details.isEmpty { Text(details).font(.system(.caption, design: .monospaced)).textSelection(.enabled) }
            Spacer()
        }.padding(24).onAppear(perform: refresh)
    }
    private func refresh() { DispatchQueue.global().async { let result = SystemMetricsSupport.run("/usr/bin/fdesetup", ["status"]) ?? "Unable to query FileVault."; DispatchQueue.main.async { status = result.trimmingCharacters(in: .whitespacesAndNewlines); details = "Recovery-key changes are managed by macOS System Settings." } } }
}
