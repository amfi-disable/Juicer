import SwiftUI

struct autoupdatecheckerview: View { @State private var output = ""; var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "Auto-Update Checker", subtitle: "Check package managers for available upgrades without applying them.", icon: "arrow.triangle.2.circlepath", refreshing: false, action: check); Button("Check Updates") { check() }.buttonStyle(.borderedProminent); ScrollView { Text(output).font(.system(.caption, design: .monospaced)).frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled) }; Spacer() }.padding(24).onAppear(perform: check) }
    private func check() { let tools = [("brew", "/opt/homebrew/bin/brew", ["outdated"]), ("npm", "/usr/local/bin/npm", ["outdated", "-g"]), ("pip", "/usr/bin/python3", ["-m", "pip", "list", "--outdated"])]; output = tools.map { "[$0.0]\n" + (SystemMetricsSupport.run($0.1, $0.2) ?? "unavailable") }.joined(separator: "\n\n") }
}
