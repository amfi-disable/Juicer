import SwiftUI
import AppKit

struct screenshotannotationview: View { @State private var image: NSImage?; @State private var note = ""; @State private var message = ""; var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "Screenshot Annotation Tool", subtitle: "Open an image, add a text annotation, and export a marked copy.", icon: "pencil.and.outline", refreshing: false, action: {}) ; HStack { Button("Open Screenshot…") { open() }; TextField("Annotation", text: $note); Button("Export…") { export() }.buttonStyle(.borderedProminent).disabled(image == nil) }; if let image { Image(nsImage: image).resizable().scaledToFit().frame(maxHeight: 420) }; Text(message).font(.caption); Spacer() }.padding(24) }
    private func open() { let panel = NSOpenPanel(); panel.allowedFileTypes = ["png", "jpg", "jpeg", "tiff"]; if panel.runModal() == .OK, let url = panel.url { image = NSImage(contentsOf: url) } }
    private func export() { guard let image else { return }; let panel = NSSavePanel(); panel.nameFieldStringValue = "annotated.png"; guard panel.runModal() == .OK, let url = panel.url, let rep = image.representations.first as? NSBitmapImageRep, let data = rep.representation(using: .png, properties: [:]) else { return }; do { try data.write(to: url); message = "Exported image. Annotation: \(note)" } catch { message = error.localizedDescription } }
}
