import SwiftUI
import AppKit

struct nltocommandview: View {
    @StateObject private var manager = NaturalLanguageCommandManager()
    @State private var copiedNotice = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Natural Language to Shell Converter")
                        .font(.title2)
                        .bold()
                    Text("Type plain English queries to generate and run validated macOS zsh commands.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            
            Divider()
            
            // Query Input
            VStack(alignment: .leading, spacing: 10) {
                Text("Describe what you want to do:")
                    .font(.headline)
                
                HStack {
                    TextField("e.g., Find files over 100MB, Kill process on port 8080, Flush DNS cache...", text: $manager.query)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { manager.translateQuery() }
                    
                    Button("Generate Command") {
                        manager.translateQuery()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            
            Divider()
            
            // Generated Command & Explanation
            if !manager.generatedCommand.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Generated Shell Command")
                            .font(.headline)
                        Spacer()
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(manager.generatedCommand, forType: .string)
                            copiedNotice = "Copied command!"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copiedNotice = "" }
                        }) {
                            Label("Copy Command", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: { manager.executeGeneratedCommand() }) {
                            Label("Run Command", systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(manager.isExecuting)
                    }
                    
                    if !copiedNotice.isEmpty {
                        Text(copiedNotice)
                            .font(.caption)
                            .foregroundStyle(.green)
                            .bold()
                    }
                    
                    Text(manager.generatedCommand)
                        .font(.system(.body, design: .monospaced))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                        )
                    
                    Text(manager.explanation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                
                Divider()
            }
            
            // Execution Output
            if !manager.executionResult.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Execution Output")
                        .font(.headline)
                    
                    ScrollView {
                        Text(manager.executionResult)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                    }
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(6)
                }
                .padding()
            }
            
            Spacer()
        }
    }
}
