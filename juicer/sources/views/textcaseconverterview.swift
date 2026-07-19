import SwiftUI
import AppKit

struct textcaseconverterview: View {
    @State private var input = ""
    @State private var style = "Upper"
    private let styles = ["Upper", "Lower", "Title", "Sentence", "Camel", "Snake", "Kebab"]
    var output: String { convert(input) }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Text Case Converter", subtitle: "Transform text into common writing and identifier cases.", icon: "textformat", refreshing: false, action: {})
            Picker("Case", selection: $style) { ForEach(styles, id: \.self) { Text($0).tag($0) } }.frame(width: 180)
            TextEditor(text: $input).overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary)).frame(minHeight: 140)
            HStack { Text(output).textSelection(.enabled); Spacer(); Button("Copy Result") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(output, forType: .string) } }
            Spacer()
        }.padding(24)
    }
    private func convert(_ value: String) -> String { let words = value.split { !$0.isLetter && !$0.isNumber }.map(String.init); switch style { case "Upper": value.uppercased(); case "Lower": value.lowercased(); case "Title": value.capitalized; case "Sentence": value.prefix(1).uppercased() + value.dropFirst().lowercased(); case "Snake": words.map { $0.lowercased() }.joined(separator: "_"); case "Kebab": words.map { $0.lowercased() }.joined(separator: "-"); default: guard let first = words.first else { return "" }; return first.lowercased() + words.dropFirst().map { $0.capitalized }.joined() } }
}
