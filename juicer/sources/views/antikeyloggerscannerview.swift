import SwiftUI

struct antikeyloggerscannerview: View {
    @State private var findings: [String] = []
    @State private var message = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Anti-Keylogger Scanner", subtitle: "Review launch agents and daemons for suspicious keylogger-like names.", icon: "keyboard.badge.ellipsis", refreshing: false, action: scan)
            HStack { Button("Scan Launch Locations") { scan() }.buttonStyle(.borderedProminent); Spacer(); Text(message).font(.caption).foregroundStyle(.secondary) }
            Text("This heuristic scanner reports filenames only; it is not a malware verdict.").font(.caption).foregroundStyle(.orange)
            List(findings, id: \.self) { Label($0, systemImage: "magnifyingglass") }.listStyle(.inset)
        }.padding(24).onAppear(perform: scan)
    }
    private func scan() { DispatchQueue.global().async { let home = FileManager.default.homeDirectoryForCurrentUser.path; let roots = ["/Library/LaunchAgents", "/Library/LaunchDaemons", "\(home)/Library/LaunchAgents"]; let candidates = roots.flatMap { (try? FileManager.default.contentsOfDirectory(atPath: $0)) ?? [] }.filter { let name = $0.lowercased(); return name.contains("keylog") || name.contains("input") || name.contains("hook") }; DispatchQueue.main.async { findings = candidates; message = "Reviewed launch locations; \(candidates.count) heuristic match(es)." } } }
}
