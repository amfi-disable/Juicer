import SwiftUI
import PDFKit
import AppKit

struct pdftoolboxview: View {
    @State private var files: [URL] = []
    @State private var message = ""
    var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "PDF Toolbox", subtitle: "Merge selected PDF documents using PDFKit.", icon: "doc.richtext", refreshing: false, action: {}) ; HStack { Button("Choose PDFs…") { choose() }; Button("Merge…") { merge() }.buttonStyle(.borderedProminent).disabled(files.count < 2); Spacer() }; Text(message).font(.caption).foregroundStyle(.secondary); List(files, id: \.self) { Text($0.path).lineLimit(1).truncationMode(.middle) }.listStyle(.inset) }.padding(24) }
    private func choose() { let panel = NSOpenPanel(); panel.allowsMultipleSelection = true; panel.allowedFileTypes = ["pdf"]; if panel.runModal() == .OK { files = panel.urls } }
    private func merge() { let save = NSSavePanel(); save.nameFieldStringValue = "merged.pdf"; guard save.runModal() == .OK, let destination = save.url else { return }; let output = PDFDocument(); for url in files { guard let document = PDFDocument(url: url) else { continue }; for index in 0..<document.pageCount { if let page = document.page(at: index) { output.insert(page, at: output.pageCount) } } }; message = output.write(to: destination) ? "Merged \(files.count) PDF(s)." : "Unable to write PDF." }
}
