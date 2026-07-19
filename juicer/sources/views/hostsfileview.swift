import SwiftUI

struct hostsfileview: View { @State private var contents = ""; @State private var message = ""; var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "Hosts File Editor", subtitle: "Review and edit /etc/hosts with explicit save control.", icon: "list.bullet.rectangle", refreshing: false, action: load); HStack { Button("Reload") { load() }; Button("Save Hosts File") { save() }.buttonStyle(.borderedProminent); Spacer(); Text(message).font(.caption).foregroundStyle(.secondary) }; TextEditor(text: $contents).font(.system(.body, design: .monospaced)).overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary)); Spacer() }.padding(24).onAppear(perform: load) }
    private func load() { contents = (try? String(contentsOfFile: "/etc/hosts", encoding: .utf8)) ?? "Unable to read /etc/hosts." }
    private func save() { do { try contents.write(toFile: "/etc/hosts", atomically: true, encoding: .utf8); message = "Hosts file saved." } catch { message = "Save failed: \(error.localizedDescription)" } }
}
