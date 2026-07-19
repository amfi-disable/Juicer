import SwiftUI
import AppKit

struct markdownpreviewerview: View {
    @State private var markdown = "# Markdown Preview\n\nWrite **Markdown** here."
    @State private var message = ""
    var body: some View { HStack(spacing: 16) { VStack(alignment: .leading) { JuicerFeatureHeader(title: "Markdown Previewer", subtitle: "Edit Markdown and preview it live.", icon: "doc.text", refreshing: false, action: {}) ; TextEditor(text: $markdown).font(.system(.body, design: .monospaced)).overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary)); Button("Export HTML…") { export() } }.frame(maxWidth: .infinity); ScrollView { if let rendered = try? AttributedString(markdown: markdown) { Text(rendered).frame(maxWidth: .infinity, alignment: .leading) } }.frame(maxWidth: .infinity).padding(16).background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8)) }.padding(24) }
    private func export() { let panel = NSSavePanel(); panel.nameFieldStringValue = "preview.html"; guard panel.runModal() == .OK, let url = panel.url else { return }; do { try "<html><body><pre>\(markdown.replacingOccurrences(of: "<", with: "&lt;"))</pre></body></html>".write(to: url, atomically: true, encoding: .utf8); message = "Exported HTML." } catch { message = error.localizedDescription } }
}
