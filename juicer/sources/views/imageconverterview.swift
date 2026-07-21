import SwiftUI
import AppKit

struct imageconverterview: View {
    @StateObject private var manager = ImageConverterManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Batch Image Compressor & Converter")
                        .font(.title2)
                        .bold()
                    Text("Batch convert and compress PNG, JPEG, WebP, and HEIC images with custom quality settings.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button("Add Images...") {
                    let panel = NSOpenPanel()
                    panel.allowedContentTypes = [.image]
                    panel.allowsMultipleSelection = true
                    if panel.runModal() == .OK {
                        manager.addFiles(panel.urls)
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            
            Divider()
            
            // Format & Quality Controls Toolbar
            HStack(spacing: 20) {
                Picker("Target Format:", selection: $manager.selectedFormat) {
                    Text("WebP").tag("WebP")
                    Text("JPEG").tag("JPEG")
                    Text("PNG").tag("PNG")
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quality: \(Int(manager.compressionQuality * 100))%")
                        .font(.caption)
                    Slider(value: $manager.compressionQuality, in: 0.1...1.0)
                        .frame(width: 150)
                }
                
                Spacer()
                
                if !manager.completionMessage.isEmpty {
                    Text(manager.completionMessage)
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.green)
                }
                
                Button("Convert All") {
                    manager.convertBatch()
                }
                .buttonStyle(.borderedProminent)
                .disabled(manager.items.isEmpty || manager.isConverting)
            }
            .padding()
            
            Divider()
            
            // File List
            if manager.items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No Images Added")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(manager.items) { item in
                        HStack {
                            Image(systemName: "photo")
                                .foregroundStyle(Color.accentColor)
                            Text(item.url.lastPathComponent)
                                .font(.headline)
                            Spacer()
                            Text("Original: \(ByteCountFormatter.string(fromByteCount: item.originalSize, countStyle: .file))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(item.status)
                                .font(.caption.monospaced())
                                .bold()
                                .foregroundStyle(item.status.contains("Done") ? Color.green : Color.primary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.inset)
            }
        }
    }
}
