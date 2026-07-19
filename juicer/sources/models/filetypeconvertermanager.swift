import Foundation
import Combine

struct ConverterInput: Identifiable {
    let id = UUID()
    let url: URL
}

final class FileTypeConverterManager: ObservableObject {
    @Published var inputs: [ConverterInput] = []
    @Published var outputFolder: URL?
    @Published var format = "png"
    @Published var working = false
    @Published var message = ""

    var ffmpegAvailable: Bool { ffmpegPath != nil }

    private var ffmpegPath: String? {
        ["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg", "/usr/bin/ffmpeg"].first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    func add(_ urls: [URL]) { inputs = urls.map { ConverterInput(url: $0) } }

    func convert() {
        guard !inputs.isEmpty, let outputFolder else { message = "Choose files and an output folder first."; return }
        working = true
        let selected = inputs
        let targetFormat = format.lowercased()
        let ffmpeg = ffmpegPath
        DispatchQueue.global(qos: .userInitiated).async {
            var completed = 0
            var failures: [String] = []
            for input in selected {
                let source = input.url
                let destination = outputFolder.appendingPathComponent(source.deletingPathExtension().lastPathComponent).appendingPathExtension(targetFormat)
                let tool: (String, [String])?
                let ext = source.pathExtension.lowercased()
                if ["jpg", "jpeg", "png", "tiff", "heic", "webp"].contains(ext) {
                    tool = ("/usr/bin/sips", ["-s", "format", targetFormat, source.path, "--out", destination.path])
                } else if ["m4a", "mp3", "wav", "aiff", "caf"].contains(ext) {
                    tool = ("/usr/bin/afconvert", ["-f", targetFormat, source.path, destination.path])
                } else if ["txt", "rtf", "doc", "docx", "html"].contains(ext) {
                    tool = ("/usr/bin/textutil", ["-convert", targetFormat, source.path, "-output", destination.path])
                } else if let ffmpeg {
                    tool = (ffmpeg, ["-y", "-i", source.path, destination.path])
                } else {
                    tool = nil
                }
                guard let tool else { failures.append(source.lastPathComponent); continue }
                if SystemMetricsSupport.run(tool.0, tool.1) != nil { completed += 1 } else { failures.append(source.lastPathComponent) }
            }
            DispatchQueue.main.async {
                self.working = false
                self.message = failures.isEmpty ? "Converted \(completed) file(s)." : "Converted \(completed); unavailable or failed: \(failures.joined(separator: ", "))."
            }
        }
    }
}
