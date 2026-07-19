import SwiftUI
import AppKit

private struct JuicerSnippet: Identifiable { let id = UUID(); var name: String; var text: String }

struct snippetexpanderview: View {
    @State private var snippets = [JuicerSnippet(name: "Date", text: "{{date}}"), JuicerSnippet(name: "Time", text: "{{time}}")]
    @State private var selected: UUID?
    @State private var name = "New Snippet"
    @State private var text = ""
    var body: some View {
        HStack(spacing: 16) {
            List(snippets, selection: $selected) { snippet in Text(snippet.name).tag(snippet.id) }.frame(width: 180)
            VStack(alignment: .leading, spacing: 12) { JuicerFeatureHeader(title: "Snippet Expander", subtitle: "Create reusable text with date, time, and clipboard variables.", icon: "text.badge.plus", refreshing: false, action: {}) ; TextField("Snippet name", text: $name); TextEditor(text: $text).overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary)); HStack { Button("New") { name = "New Snippet"; text = ""; selected = nil }; Button("Save") { save() }.buttonStyle(.borderedProminent); Button("Copy Expanded") { copy() } } }.padding(.vertical, 8)
        }.padding(24).onChange(of: selected) { _, value in if let value, let snippet = snippets.first(where: { $0.id == value }) { name = snippet.name; text = snippet.text } }
    }
    private func save() { if let selected, let index = snippets.firstIndex(where: { $0.id == selected }) { snippets[index] = JuicerSnippet(name: name, text: text) } else { snippets.append(JuicerSnippet(name: name, text: text)) } }
    private func copy() { let formatter = DateFormatter(); formatter.dateStyle = .medium; let time = DateFormatter(); time.timeStyle = .medium; let expanded = text.replacingOccurrences(of: "{{date}}", with: formatter.string(from: Date())).replacingOccurrences(of: "{{time}}", with: time.string(from: Date())).replacingOccurrences(of: "{{clipboard}}", with: NSPasteboard.general.string(forType: .string) ?? ""); NSPasteboard.general.clearContents(); NSPasteboard.general.setString(expanded, forType: .string) }
}
