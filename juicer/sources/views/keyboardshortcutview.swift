import SwiftUI

struct keyboardshortcutview: View {
    @State private var command = ""
    @State private var shortcut = ""
    @State private var message = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Keyboard Shortcut Manager", subtitle: "Add a custom menu command shortcut to macOS application preferences.", icon: "keyboard", refreshing: false, action: {})
            TextField("Menu command title, for example Save", text: $command)
            TextField("Shortcut glyphs, for example @s", text: $shortcut)
            Button("Save Shortcut") { save() }.buttonStyle(.borderedProminent)
            Text("Shortcut glyphs follow NSUserKeyEquivalents notation. Restart the target app to reload the preference.").font(.caption).foregroundStyle(.secondary)
            if !message.isEmpty { Text(message).font(.caption).foregroundStyle(.secondary) }
            Spacer()
        }.padding(24)
    }
    private func save() { guard !command.isEmpty, !shortcut.isEmpty else { message = "Enter a command and shortcut."; return }; let result = SystemMetricsSupport.run("/usr/bin/defaults", ["write", "-g", "NSUserKeyEquivalents", "-dict-add", command, shortcut]); message = result == nil ? "Unable to save shortcut." : "Saved \(command) for all supported apps." }
}
