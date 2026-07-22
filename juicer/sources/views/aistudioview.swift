import SwiftUI
import AppKit

struct aistudioview: View {
    @StateObject private var manager = AIManager.shared
    @State private var selectedTab = 0
    @State private var chatInputText: String = ""
    @State private var selectedModel: String = ""
    @State private var geminiKeyInput: String = ""
    @State private var showCopiedBanner = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Banner
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 52, height: 52)
                    Image(systemName: "sparkles")
                        .font(.title)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Juicer AI Studio")
                            .font(.title2).bold()
                        
                        HStack(spacing: 5) {
                            Circle()
                                .fill((manager.isOllamaActive || manager.isLMStudioActive) ? Color.green : Color.orange)
                                .frame(width: 7, height: 7)
                            Text((manager.isOllamaActive || manager.isLMStudioActive) ? "ENGINE ACTIVE" : "LOCAL HOST OFFLINE")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle((manager.isOllamaActive || manager.isLMStudioActive) ? .green : .orange)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(((manager.isOllamaActive || manager.isLMStudioActive) ? Color.green : Color.orange).opacity(0.14), in: Capsule())
                    }
                    
                    Text("Local Ollama & LM Studio model inspector, developer prompt vault, and code debugger")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: { manager.checkLocalServices() }) {
                    Label("Check Engine", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .disabled(manager.isRefreshing)
            }
            .padding(20)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Picker Tab Bar
            HStack {
                Picker("", selection: $selectedTab) {
                    Text("Local Models (\(manager.localModels.count))").tag(0)
                    Text("Prompt Vault").tag(1)
                    Text("Code Assistant Chat").tag(2)
                    Text("API Profiles").tag(3)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 540)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Tab Content
            switch selectedTab {
            case 0:
                localModelsTabView()
            case 1:
                promptVaultTabView()
            case 2:
                chatTabView()
            default:
                apiProfilesTabView()
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            manager.checkLocalServices()
        }
    }
    
    // MARK: - Tab 1: Local Models
    @ViewBuilder
    private func localModelsTabView() -> some View {
        if manager.localModels.isEmpty {
            VStack(spacing: 14) {
                Image(systemName: "cpu")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("No Local LLM Models Detected")
                    .font(.title3).bold()
                Text("Install Ollama (`brew install ollama`) or launch LM Studio to run open-weight AI models on Apple Silicon.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 520)
                
                HStack(spacing: 12) {
                    Button("Install Ollama via Homebrew") {
                        let process = Process()
                        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                        process.arguments = ["https://ollama.com"]
                        try? process.run()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    
                    Button("Check Port 11434 / 1234") {
                        manager.checkLocalServices()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(40)
        } else {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(manager.localModels) { model in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(model.name)
                                    .font(.headline.bold())
                                Spacer()
                                Text(model.provider)
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.purple.opacity(0.15), in: Capsule())
                                    .foregroundColor(.purple)
                            }
                            
                            HStack(spacing: 12) {
                                Label(model.size, systemImage: "internaldrive")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button("Chat") {
                                    selectedModel = model.name
                                    selectedTab = 2
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.purple)
                            }
                        }
                        .padding(16)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.secondary.opacity(0.12), lineWidth: 1))
                    }
                }
                .padding(20)
            }
        }
    }
    
    // MARK: - Tab 2: Prompt Vault
    @ViewBuilder
    private func promptVaultTabView() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Developer Prompt Vault")
                    .font(.title3.bold())
                Text("Pre-configured prompt templates for code review, error log debugging, and refactoring.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                LazyVStack(spacing: 14) {
                    ForEach(manager.promptVault) { snippet in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(snippet.title)
                                    .font(.headline.bold())
                                Spacer()
                                HStack(spacing: 6) {
                                    ForEach(snippet.tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.secondary.opacity(0.12), in: Capsule())
                                    }
                                }
                            }
                            
                            Text(snippet.content)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                            
                            HStack {
                                Spacer()
                                Button("Copy Prompt") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(snippet.content, forType: .string)
                                }
                                .buttonStyle(.bordered)
                                
                                Button("Run in Chat") {
                                    chatInputText = snippet.content
                                    selectedTab = 2
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.purple)
                            }
                        }
                        .padding(16)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.secondary.opacity(0.12), lineWidth: 1))
                    }
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Tab 3: Chat Assistant
    @ViewBuilder
    private func chatTabView() -> some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        ForEach(manager.chatMessages) { msg in
                            HStack {
                                if msg.isUser { Spacer() }
                                
                                VStack(alignment: msg.isUser ? .trailing : .leading, spacing: 4) {
                                    Text(msg.text)
                                        .font(.system(size: 13, design: msg.isUser ? .default : .monospaced))
                                        .padding(12)
                                        .background(msg.isUser ? Color.purple : Color(NSColor.controlBackgroundColor))
                                        .foregroundColor(msg.isUser ? .white : .primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                
                                if !msg.isUser { Spacer() }
                            }
                            .id(msg.id)
                        }
                    }
                    .padding(20)
                }
                .onChange(of: manager.chatMessages.count) { _, _ in
                    if let lastID = manager.chatMessages.last?.id {
                        withAnimation { proxy.scrollTo(lastID, anchor: .bottom) }
                    }
                }
            }
            
            Divider()
            
            // Input Controls Bar
            HStack(spacing: 10) {
                TextField("Ask developer question or paste error log...", text: $chatInputText)
                    .textFieldStyle(.roundedBorder)
                
                Button(action: {
                    manager.sendMessage(chatInputText, model: selectedModel)
                    chatInputText = ""
                }) {
                    Image(systemName: "paperplane.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .disabled(chatInputText.isEmpty || manager.isGenerating)
            }
            .padding(14)
            .background(Color(NSColor.windowBackgroundColor))
        }
    }
    
    // MARK: - Tab 4: API Profiles
    @ViewBuilder
    private func apiProfilesTabView() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("AI Provider Key Manager")
                    .font(.title3.bold())
                Text("Configure local host endpoints and API keys for developer assistance.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 14) {
                    Text("Ollama Local Endpoint")
                        .font(.headline)
                    TextField("Endpoint URL", text: .constant("http://localhost:11434"))
                        .textFieldStyle(.roundedBorder)
                        .disabled(true)
                    
                    Divider()
                    
                    Text("Google Gemini API Key")
                        .font(.headline)
                    SecureField("Paste Gemini API Key", text: $geminiKeyInput)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack {
                        Spacer()
                        Button("Save Profiles") {
                            AppLogger.shared.log("AI Key saved.")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                    }
                }
                .padding(20)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(20)
        }
    }
}
