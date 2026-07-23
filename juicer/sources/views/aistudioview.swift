import SwiftUI
import AppKit

struct AIModelItem: Identifiable {
    var id: String { name }
    let name: String
    let size: String
    let modified: String
}

class AIStudioManager: ObservableObject {
    @Published var localModels: [AIModelItem] = []
    @Published var isOllamaRunning = false
    @Published var promptInput = ""
    @Published var chatResponse = ""
    @Published var isGenerating = false
    
    init() {
        self.scanLocalModels()
    }
    
    func scanLocalModels() {
        Task.detached(priority: .userInitiated) {
            let output = self.runShellCommand("ollama list")
            var items: [AIModelItem] = []
            let lines = output.components(separatedBy: "\n")
            for (index, line) in lines.enumerated() {
                if index == 0 || line.isEmpty { continue }
                let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                if parts.count >= 3 {
                    let name = parts[0]
                    let size = parts[parts.count - 2] + " " + parts[parts.count - 1]
                    items.append(AIModelItem(name: name, size: size, modified: "Local"))
                }
            }
            
            await MainActor.run {
                self.localModels = items
                self.isOllamaRunning = !items.isEmpty
            }
        }
    }
    
    func generateResponse(prompt: String) {
        guard !prompt.isEmpty else { return }
        self.isGenerating = true
        self.chatResponse = "Generating response via local Ollama instance..."
        
        Task.detached(priority: .userInitiated) {
            let safePrompt = prompt.replacingOccurrences(of: "\"", with: "\\\"")
            let modelName = self.localModels.first?.name ?? "llama3"
            let cmd = "ollama run \(modelName) \"\(safePrompt)\""
            let output = self.runShellCommand(cmd)
            
            await MainActor.run {
                self.chatResponse = output.isEmpty ? "No response received. Ensure Ollama daemon is running (`ollama serve`)." : output
                self.isGenerating = false
            }
        }
    }
    
    private func runShellCommand(_ cmd: String) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", cmd]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch { return "" }
    }
}

struct aistudioview: View {
    @StateObject private var manager = AIStudioManager()
    @State private var selectedTab = "Chat"
    @State private var promptText = "Explain how async/await works in Swift 6 concurrency."
    
    var body: some View {
        VStack(spacing: 0) {
            JuicerFeatureHeader(
                title: "Juicer AI & LLM Studio",
                subtitle: "Monitor local Ollama models, manage developer prompts, and execute AI code refactoring.",
                icon: "sparkles",
                refreshing: manager.isGenerating,
                action: { manager.scanLocalModels() }
            )
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            
            Divider()
            
            HStack {
                Picker("", selection: $selectedTab) {
                    Text("AI Chat Assistant").tag("Chat")
                    Text("Local Models (\(manager.localModels.count))").tag("Models")
                    Text("Prompt Vault").tag("Vault")
                }
                .pickerStyle(.segmented)
                .frame(width: 340)
                
                Spacer()
            }
            .padding()
            
            Divider()
            
            if selectedTab == "Chat" {
                chatView()
            } else if selectedTab == "Models" {
                modelsView()
            } else {
                vaultView()
            }
        }
        .allowWindowDragAndFit()
    }
    
    @ViewBuilder
    private func chatView() -> some View {
        VStack(spacing: 12) {
            HStack {
                TextField("Ask local AI or paste code to explain...", text: $promptText)
                    .textFieldStyle(.roundedBorder)
                Button("Send Prompt") {
                    manager.generateResponse(prompt: promptText)
                }
                .buttonStyle(.borderedProminent)
                .disabled(manager.isGenerating || promptText.isEmpty)
            }
            
            TextEditor(text: .constant(manager.chatResponse.isEmpty ? "Response output will appear here..." : manager.chatResponse))
                .font(.system(.body, design: .monospaced))
                .cornerRadius(8)
        }
        .padding()
    }
    
    @ViewBuilder
    private func modelsView() -> some View {
        if manager.localModels.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "cpu")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)
                Text("No Local Ollama Models Detected")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("Run `ollama pull llama3` in terminal to download a local LLM.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(manager.localModels) { model in
                HStack {
                    Image(systemName: "sparkles").foregroundStyle(.purple)
                    VStack(alignment: .leading) {
                        Text(model.name).bold()
                        Text("Size: \(model.size)").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("Ready").font(.caption).bold().foregroundStyle(.green)
                }
                .padding(.vertical, 4)
            }
            .listStyle(.inset)
        }
    }
    
    @ViewBuilder
    private func vaultView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Developer Prompt Templates").font(.headline)
            List {
                promptTemplateRow(title: "Code Refactor & Modularize", bodyText: "Refactor the following code to adhere to SOLID principles and Swift 6 concurrency safety.")
                promptTemplateRow(title: "JSDoc / SwiftDoc Generator", bodyText: "Add comprehensive inline docstrings explaining parameters, returns, and thrown errors.")
                promptTemplateRow(title: "Unit Test Case Generator", bodyText: "Write comprehensive unit test cases covering edge cases for this function.")
            }
            .listStyle(.inset)
        }
        .padding()
    }
    
    private func promptTemplateRow(title: String, bodyText: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).bold()
            Text(bodyText).font(.caption).foregroundStyle(.secondary)
            Button("Use Template") {
                promptText = bodyText
                selectedTab = "Chat"
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
}
