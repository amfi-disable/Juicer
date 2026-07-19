import SwiftUI
import AppKit

struct filetypeconverterview: View {
    @StateObject private var manager = FileTypeConverterManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "File Type Converter", subtitle: "Batch convert common images, audio, video, and document files.", icon: "arrow.triangle.2.circlepath", refreshing: manager.working, action: {})
            HStack {
                Button("Choose Files…") { chooseFiles() }
                Button("Output Folder…") { chooseFolder() }
                Spacer()
                Picker("Format", selection: $manager.format) { ForEach(formats, id: \.self) { Text($0.uppercased()).tag($0) } }
                    .frame(width: 160)
                Button("Convert") { manager.convert() }.buttonStyle(.borderedProminent).disabled(manager.working || manager.inputs.isEmpty || manager.outputFolder == nil)
            }
            if let folder = manager.outputFolder { Text("Output: \(folder.path)").font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle) }
            if !manager.ffmpegAvailable { Text("Video conversion requires ffmpeg at /opt/homebrew/bin/ffmpeg or /usr/local/bin/ffmpeg.").font(.caption).foregroundStyle(.orange) }
            if !manager.message.isEmpty { Text(manager.message).font(.caption).foregroundStyle(.secondary) }
            List(manager.inputs) { input in Label(input.url.path, systemImage: "doc").lineLimit(1).truncationMode(.middle) }.listStyle(.inset)
        }.padding(24)
    }

    private let formats = ["png", "jpg", "heic", "tiff", "m4a", "mp3", "wav", "pdf", "rtf", "docx"]
    private func chooseFiles() { let panel = NSOpenPanel(); panel.allowsMultipleSelection = true; if panel.runModal() == .OK { manager.add(panel.urls) } }
    private func chooseFolder() { let panel = NSOpenPanel(); panel.canChooseDirectories = true; panel.canChooseFiles = false; if panel.runModal() == .OK { manager.outputFolder = panel.url } }
}
