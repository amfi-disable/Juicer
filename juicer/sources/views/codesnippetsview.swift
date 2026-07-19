import SwiftUI

private struct CodeSnippet: Identifiable { let id = UUID(); var title: String; var language: String; var code: String }
struct codesnippetsview: View {
    @State private var snippets = [CodeSnippet(title: "Hello Swift", language: "swift", code: "print(\"Hello\")")]
    @State private var query = ""
    @State private var selected: UUID?
    private var filtered: [CodeSnippet] { snippets.filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) || $0.language.localizedCaseInsensitiveContains(query) } }
    var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "Code Snippets Library", subtitle: "Store searchable, language-tagged code blocks.", icon: "curlybraces.square", refreshing: false, action: {}) ; TextField("Search snippets", text: $query); List(filtered) { snippet in HStack { VStack(alignment: .leading) { Text(snippet.title); Text(snippet.language).font(.caption).foregroundStyle(.secondary) }; Spacer(); Button("Copy") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(snippet.code, forType: .string) }.buttonStyle(.borderless) } }.listStyle(.inset) }.padding(24) }
}
