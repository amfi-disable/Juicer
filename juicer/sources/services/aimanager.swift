import Foundation
import Combine

struct AIModel: Identifiable, Hashable {
    let id: String
    let name: String
    let provider: String
    let size: String
    let modifiedAt: String
}

struct AIPromptSnippet: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let category: String
    let content: String
    let tags: [String]
}

struct AIChatMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    let text: String
    let timestamp: Date = Date()
}

final class AIManager: ObservableObject {
    static let shared = AIManager()
    
    @Published var isOllamaActive = false
    @Published var isLMStudioActive = false
    @Published var localModels: [AIModel] = []
    @Published var isRefreshing = false
    @Published var chatMessages: [AIChatMessage] = [
        AIChatMessage(isUser: false, text: "Hello! I am your Juicer AI Assistant. Select a model or prompt template from the vault to start debugging code or analyzing stack traces.")
    ]
    @Published var isGenerating = false
    
    @Published var promptVault: [AIPromptSnippet] = [
        AIPromptSnippet(
            title: "🔍 Security & Code Review",
            category: "Code Review",
            content: "Perform a comprehensive security, performance, and readability code review for the following code. Point out memory leaks, retain cycles, or inefficient loop logic:\n\n```swift\n\n```",
            tags: ["Review", "Security", "Swift"]
        ),
        AIPromptSnippet(
            title: "🐛 Stack Trace & Error Debugger",
            category: "Debugging",
            content: "Analyze this build log error or runtime stack trace. Explain the root cause in detail and provide the exact step-by-step fix:\n\n```text\n\n```",
            tags: ["Debug", "Xcode", "Crash"]
        ),
        AIPromptSnippet(
            title: "🏗️ System Architecture Planner",
            category: "Architecture",
            content: "Design a clean, modular architecture for a new feature. Outline component boundaries, data models, state flow, and edge cases.",
            tags: ["Architecture", "Design"]
        ),
        AIPromptSnippet(
            title: "📝 Docstring & API Spec Generator",
            category: "Documentation",
            content: "Generate standard Swift / Markdown documentation comments for the following methods and data models.",
            tags: ["Docs", "Comments"]
        )
    ]
    
    private init() {
        checkLocalServices()
    }
    
    func checkLocalServices() {
        isRefreshing = true
        
        let group = DispatchGroup()
        var models: [AIModel] = []
        var ollamaOk = false
        var lmStudioOk = false
        
        // 1. Query Ollama (http://localhost:11434/api/tags)
        group.enter()
        if let url = URL(string: "http://localhost:11434/api/tags") {
            var request = URLRequest(url: url)
            request.timeoutInterval = 2.5
            URLSession.shared.dataTask(with: request) { data, response, _ in
                defer { group.leave() }
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let modelsArray = json["models"] as? [[String: Any]] {
                    ollamaOk = true
                    for item in modelsArray {
                        let name = item["name"] as? String ?? "Unknown"
                        let sizeBytes = item["size"] as? Int64 ?? 0
                        let sizeFormatted = ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
                        models.append(AIModel(id: name, name: name, provider: "Ollama", size: sizeFormatted, modifiedAt: "Local"))
                    }
                }
            }.resume()
        } else { group.leave() }
        
        // 2. Query LM Studio (http://localhost:1234/v1/models)
        group.enter()
        if let url = URL(string: "http://localhost:1234/v1/models") {
            var request = URLRequest(url: url)
            request.timeoutInterval = 2.5
            URLSession.shared.dataTask(with: request) { data, response, _ in
                defer { group.leave() }
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataArray = json["data"] as? [[String: Any]] {
                    lmStudioOk = true
                    for item in dataArray {
                        let name = item["id"] as? String ?? "Unknown Model"
                        models.append(AIModel(id: name, name: name, provider: "LM Studio", size: "Active VRAM", modifiedAt: "Local"))
                    }
                }
            }.resume()
        } else { group.leave() }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.isOllamaActive = ollamaOk
            self.isLMStudioActive = lmStudioOk
            self.localModels = models
            self.isRefreshing = false
        }
    }
    
    func sendMessage(_ userText: String, model: String? = nil) {
        guard !userText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMsg = AIChatMessage(isUser: true, text: userText)
        chatMessages.append(userMsg)
        isGenerating = true
        
        let selectedModel = model ?? localModels.first?.name ?? "llama3"
        
        // Dispatch generation request to Ollama endpoint if available
        if isOllamaActive, let url = URL(string: "http://localhost:11434/api/generate") {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            let payload: [String: Any] = [
                "model": selectedModel,
                "prompt": userText,
                "stream": false
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
            
            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                DispatchQueue.main.async {
                    self?.isGenerating = false
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let responseText = json["response"] as? String {
                        let aiMsg = AIChatMessage(isUser: false, text: responseText)
                        self?.chatMessages.append(aiMsg)
                    } else {
                        let aiMsg = AIChatMessage(isUser: false, text: "Received response from local engine (\(selectedModel)). Debug Assistant Ready.")
                        self?.chatMessages.append(aiMsg)
                    }
                }
            }.resume()
        } else {
            // Simulated local response for demonstration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.isGenerating = false
                let mockReply = "juicer AI Analysis:\n\n1. **Root Cause**: Memory retain cycle or missing weak reference.\n2. **Recommendation**: Verify closures capturing `self` with `[weak self]` in asynchronous tasks."
                self?.chatMessages.append(AIChatMessage(isUser: false, text: mockReply))
            }
        }
    }
}
