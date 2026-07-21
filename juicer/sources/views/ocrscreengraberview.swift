import SwiftUI
import AppKit

struct ocrscreengraberview: View {
    @StateObject private var manager = OCRScreenGrabberManager()
    @State private var copiedNotice = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("OCR Screen Area Grabber")
                        .font(.title2)
                        .bold()
                    Text("Capture any region of your screen to instantly extract and copy text using Vision OCR.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: { manager.captureAndRecognizeText() }) {
                    Label("Capture Screen Text", systemImage: "viewfinder")
                }
                .buttonStyle(.borderedProminent)
                .disabled(manager.isProcessing)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            
            Divider()
            
            // Status Bar
            if manager.isProcessing {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                    Text(manager.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color(NSColor.windowBackgroundColor))
                Divider()
            } else if !manager.statusMessage.isEmpty {
                HStack {
                    Text(manager.statusMessage)
                        .font(.caption)
                        .bold()
                        .foregroundStyle(manager.recognizedText.isEmpty ? .orange : .green)
                    Spacer()
                }
                .padding(8)
                .background(Color(NSColor.windowBackgroundColor))
                Divider()
            }
            
            // Recognized Text Editor
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Recognized Text Output")
                        .font(.headline)
                    Spacer()
                    if !manager.recognizedText.isEmpty {
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(manager.recognizedText, forType: .string)
                            copiedNotice = "Copied to clipboard!"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copiedNotice = "" }
                        }) {
                            Label("Copy Text", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                
                if !copiedNotice.isEmpty {
                    Text(copiedNotice)
                        .font(.caption)
                        .foregroundStyle(.green)
                        .bold()
                        .padding(.horizontal)
                }
                
                TextEditor(text: $manager.recognizedText)
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                    .padding()
            }
        }
    }
}
