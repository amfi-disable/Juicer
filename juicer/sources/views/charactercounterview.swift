import SwiftUI
import AppKit

struct charactercounterview: View {
    @State private var text = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Character & Word Counter", subtitle: "Count characters, words, lines, and bytes in typed or pasted text.", icon: "number", refreshing: false, action: paste)
            TextEditor(text: $text).overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary)).frame(minHeight: 220)
            HStack { metric("Characters", text.count); metric("Words", text.split { $0.isWhitespace || $0.isNewline }.count); metric("Lines", text.isEmpty ? 0 : text.split(separator: "\n", omittingEmptySubsequences: false).count); metric("UTF-8 bytes", text.utf8.count) }
            Spacer()
        }.padding(24)
    }
    private func metric(_ title: String, _ value: Int) -> some View { VStack(alignment: .leading) { Text("\(value)").font(.title2.bold()); Text(title).font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading) }
    private func paste() { text = NSPasteboard.general.string(forType: .string) ?? text }
}
