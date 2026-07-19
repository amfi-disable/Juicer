import SwiftUI

struct shortcutrunnerview: View { @State private var name = ""; @State private var output = ""; var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "Automator & Shortcut Runner", subtitle: "Run a named macOS Shortcut from Juicer.", icon: "command", refreshing: false, action: list); HStack { TextField("Shortcut name", text: $name); Button("Run") { run() }.buttonStyle(.borderedProminent) }; ScrollView { Text(output).font(.system(.caption, design: .monospaced)).frame(maxWidth: .infinity, alignment: .leading) }; Spacer() }.padding(24) } 
    private func list() { output = SystemMetricsSupport.run("/usr/bin/shortcuts", ["list"]) ?? "Unable to list shortcuts." }
    private func run() { output = SystemMetricsSupport.run("/usr/bin/shortcuts", ["run", name]) ?? "Unable to run shortcut." }
}
