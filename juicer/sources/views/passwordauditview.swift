import SwiftUI

struct passwordauditview: View {
    @State private var result = "No audit run"
    @State private var working = false
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Password Audit", subtitle: "Review keychain entries for account hygiene without exporting passwords.", icon: "key.fill", refreshing: working, action: audit)
            Button("Audit Keychain") { audit() }.buttonStyle(.borderedProminent).disabled(working)
            Text("macOS protects keychain contents behind user approval. Juicer never displays or stores password values; use a dedicated password manager for reuse and strength analysis.").font(.caption).foregroundStyle(.secondary)
            Text(result).font(.system(.body, design: .monospaced)).textSelection(.enabled)
            Spacer()
        }.padding(24)
    }
    private func audit() { working = true; DispatchQueue.global().async { let output = SystemMetricsSupport.run("/usr/bin/security", ["dump-keychain"]) ?? "Unable to access the keychain."; let records = output.components(separatedBy: "class: ").count - 1; DispatchQueue.main.async { result = output.contains("Unable") ? output : "Found approximately \(max(records, 0)) keychain record(s). Password values were not displayed."; working = false } } }
}
