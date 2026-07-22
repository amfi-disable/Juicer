import SwiftUI
import AppKit

struct converterstudioview: View {
    @StateObject private var manager = ConverterManager.shared
    @State private var selectedTab = 0
    
    // Doc Tab
    @State private var docTargetFormat = "DOCX"
    @State private var selectedDocURL: URL? = nil
    
    // Image Tab
    @State private var imageTargetFormat = "PNG"
    @State private var selectedImageURL: URL? = nil
    
    // Code Schema Tab
    @State private var schemaInputText = "{\n  \"id\": 101,\n  \"name\": \"Juicer Studio\",\n  \"active\": true\n}"
    @State private var schemaTargetFormat = "Swift Struct"
    @State private var schemaOutputText = ""
    
    // Archive Tab
    @State private var archiveStripMetadata = true
    
    let docFormats = ["DOCX", "PDF", "HTML", "RTF", "TXT"]
    let imageFormats = ["PNG", "JPEG", "WebP", "TIFF", "BMP"]
    let schemaFormats = ["Swift Struct", "TypeScript", "YAML"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Banner
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 52, height: 52)
                    Image(systemName: "arrow.triangle.2.circlepath.doc.on.clipboard")
                        .font(.title)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Juicer Converter Studio")
                            .font(.title2).bold()
                        
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 7, height: 7)
                            Text("OFFLINE ENGINE READY")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(.green)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.14), in: Capsule())
                    }
                    
                    Text("Universal offline converter for documents (MD, DOCX, PDF), images, code schemas, and archives")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(20)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Picker Tab Bar
            HStack {
                Picker("", selection: $selectedTab) {
                    Text("Documents (MD, DOCX, PDF)").tag(0)
                    Text("Images (HEIC, PNG, WEBP)").tag(1)
                    Text("Code Schemas (JSON ➔ Swift/TS)").tag(2)
                    Text("Archives & Compression").tag(3)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 620)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Tab Content
            switch selectedTab {
            case 0:
                docTabView()
            case 1:
                imageTabView()
            case 2:
                schemaTabView()
            default:
                archiveTabView()
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Tab 1: Documents & Text
    @ViewBuilder
    private func docTabView() -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "doc.richtext.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                Text("Markdown & Document Converter")
                    .font(.title3.bold())
                Text("Convert Markdown (.md), DOCX, HTML, and RTF documents offline.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 14)
            
            // Drop Zone Card
            VStack(spacing: 14) {
                if let url = selectedDocURL {
                    HStack(spacing: 10) {
                        Image(systemName: "doc.text")
                            .font(.title2)
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(url.lastPathComponent)
                                .font(.headline.bold())
                            Text(url.path)
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Change File") { chooseDocFile() }
                            .buttonStyle(.bordered)
                    }
                    .padding(14)
                    .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                } else {
                    Button(action: { chooseDocFile() }) {
                        VStack(spacing: 8) {
                            Image(systemName: "arrow.down.doc.fill")
                                .font(.title)
                                .foregroundColor(.orange)
                            Text("Select Document File (.md, .docx, .html, .rtf)")
                                .font(.headline)
                            Text("Click to browse local files")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6])))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 40)
            
            // Convert Controls Bar
            HStack(spacing: 16) {
                Text("Target Format:")
                    .font(.headline)
                
                Picker("", selection: $docTargetFormat) {
                    ForEach(docFormats, id: \.self) { fmt in
                        Text(fmt).tag(fmt)
                    }
                }
                .frame(width: 140)
                
                Button("Convert Document Now") {
                    if let input = selectedDocURL {
                        manager.convertDocument(inputURL: input, targetFormat: docTargetFormat) { out in
                            if let out = out { NSWorkspace.shared.selectFile(out.path, inFileViewerRootedAtPath: "") }
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(selectedDocURL == nil || manager.isConverting)
            }
            
            if !manager.statusMessage.isEmpty {
                Text(manager.statusMessage)
                    .font(.caption.bold())
                    .foregroundColor(.green)
            }
            
            Spacer()
        }
        .padding(20)
    }
    
    private func chooseDocFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.text, .plainText, .html, .rtf]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            selectedDocURL = url
        }
    }
    
    // MARK: - Tab 2: Image Converter
    @ViewBuilder
    private func imageTabView() -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "photo.stack.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.yellow)
                Text("Image Format Converter")
                    .font(.title3.bold())
                Text("Convert HEIC, PNG, JPEG, WebP, and TIFF images offline.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 14)
            
            VStack(spacing: 14) {
                if let url = selectedImageURL {
                    HStack(spacing: 10) {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundColor(.yellow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(url.lastPathComponent)
                                .font(.headline.bold())
                            Text(url.path)
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Change Image") { chooseImageFile() }
                            .buttonStyle(.bordered)
                    }
                    .padding(14)
                    .background(Color.yellow.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                } else {
                    Button(action: { chooseImageFile() }) {
                        VStack(spacing: 8) {
                            Image(systemName: "arrow.down.app.fill")
                                .font(.title)
                                .foregroundColor(.yellow)
                            Text("Select Image File (.heic, .png, .jpg, .webp, .tiff)")
                                .font(.headline)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6])))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 40)
            
            HStack(spacing: 16) {
                Text("Output Format:")
                    .font(.headline)
                
                Picker("", selection: $imageTargetFormat) {
                    ForEach(imageFormats, id: \.self) { fmt in
                        Text(fmt).tag(fmt)
                    }
                }
                .frame(width: 140)
                
                Button("Convert Image") {
                    if let input = selectedImageURL {
                        manager.convertImage(inputURL: input, targetFormat: imageTargetFormat) { out in
                            if let out = out { NSWorkspace.shared.selectFile(out.path, inFileViewerRootedAtPath: "") }
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(selectedImageURL == nil || manager.isConverting)
            }
            
            Spacer()
        }
        .padding(20)
    }
    
    private func chooseImageFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image, .png, .jpeg, .heic, .tiff]
        panel.canChooseFiles = true
        if panel.runModal() == .OK, let url = panel.url {
            selectedImageURL = url
        }
    }
    
    // MARK: - Tab 3: Code & Schemas
    @ViewBuilder
    private func schemaTabView() -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Target Output:")
                    .font(.headline)
                Picker("", selection: $schemaTargetFormat) {
                    ForEach(schemaFormats, id: \.self) { fmt in
                        Text(fmt).tag(fmt)
                    }
                }
                .frame(width: 160)
                
                Spacer()
                
                Button("Convert JSON") {
                    schemaOutputText = manager.convertCodeSchema(input: schemaInputText, fromFormat: "JSON", toFormat: schemaTargetFormat)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Input JSON:")
                        .font(.caption.bold())
                    TextEditor(text: $schemaInputText)
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Generated \(schemaTargetFormat):")
                        .font(.caption.bold())
                    TextEditor(text: $schemaOutputText)
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .background(Color.black, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Tab 4: Archives
    @ViewBuilder
    private func archiveTabView() -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "archivebox.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                Text("Archive & Metadata Cleaner")
                    .font(.title3.bold())
                Text("Compress folders to `.zip` or `.tar.gz` with optional `.DS_Store` stripping.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)
            
            Toggle("Automatically Strip `.DS_Store` & `__MACOSX` files", isOn: $archiveStripMetadata)
                .font(.headline)
            
            Button("Select Folder to Compress (.zip)") {
                let panel = NSOpenPanel()
                panel.canChooseDirectories = true
                panel.canChooseFiles = false
                if panel.runModal() == .OK, let folderURL = panel.url {
                    let zipURL = folderURL.appendingPathExtension("zip")
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
                    process.arguments = ["-c", "-k", "--sequesterRsrc", folderURL.path, zipURL.path]
                    try? process.run()
                    process.waitUntilExit()
                    NSWorkspace.shared.selectFile(zipURL.path, inFileViewerRootedAtPath: "")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            
            Spacer()
        }
        .padding(20)
    }
}
