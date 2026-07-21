import Foundation
import Combine

struct NaturalLanguageCommandRule {
    let keywords: [String]
    let commandTemplate: (String) -> String
    let description: String
    let category: String
}

class NaturalLanguageCommandManager: ObservableObject {
    @Published var query: String = ""
    @Published var generatedCommand: String = ""
    @Published var explanation: String = ""
    @Published var executionResult: String = ""
    @Published var isExecuting: Bool = false
    
    private let rules: [NaturalLanguageCommandRule] = [
        NaturalLanguageCommandRule(
            keywords: ["find", "large", "file", "size", "mb", "gb"],
            commandTemplate: { q in "find . -type f -size +100M -exec ls -lh {} +" },
            description: "Find files larger than 100MB recursively in the current directory.",
            category: "File System"
        ),
        NaturalLanguageCommandRule(
            keywords: ["kill", "port", "listening"],
            commandTemplate: { q in
                if let port = q.components(separatedBy: CharacterSet.decimalDigits.inverted).first(where: { !$0.isEmpty }) {
                    return "lsof -ti:\(port) | xargs kill -9"
                }
                return "lsof -ti:8080 | xargs kill -9"
            },
            description: "Find process listening on a port and forcefully terminate it.",
            category: "Process & Network"
        ),
        NaturalLanguageCommandRule(
            keywords: ["flush", "dns", "cache"],
            commandTemplate: { q in "sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder" },
            description: "Flush macOS local DNS resolver cache.",
            category: "Networking"
        ),
        NaturalLanguageCommandRule(
            keywords: ["empty", "trash"],
            commandTemplate: { q in "rm -rf ~/.Trash/*" },
            description: "Permanently empty user Trash folder from command line.",
            category: "Storage"
        ),
        NaturalLanguageCommandRule(
            keywords: ["gatekeeper", "quarantine", "strip"],
            commandTemplate: { q in "xattr -cr /Applications/TargetApp.app" },
            description: "Recursively strip Gatekeeper quarantine extended attributes from an application.",
            category: "Security"
        ),
        NaturalLanguageCommandRule(
            keywords: ["symlink", "broken", "alias"],
            commandTemplate: { q in "find . -type l ! -exec test -e {} \\; -print" },
            description: "Locate broken symbolic links pointing to non-existent files.",
            category: "File System"
        ),
        NaturalLanguageCommandRule(
            keywords: ["git", "commit", "undo", "last"],
            commandTemplate: { q in "git reset --soft HEAD~1" },
            description: "Undo the last git commit while keeping all modified changes staged.",
            category: "Developer Tools"
        )
    ]
    
    func translateQuery() {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else {
            generatedCommand = ""
            explanation = ""
            return
        }
        
        for rule in rules {
            if rule.keywords.contains(where: { q.contains($0) }) {
                generatedCommand = rule.commandTemplate(q)
                explanation = "\(rule.description) [Category: \(rule.category)]"
                return
            }
        }
        
        // Fallback generic search
        generatedCommand = "find . -name \"*\(q)*\""
        explanation = "Search for files matching query keyword in current directory."
    }
    
    func executeGeneratedCommand() {
        guard !generatedCommand.isEmpty else { return }
        isExecuting = true
        executionResult = "Executing..."
        
        Task.detached(priority: .userInitiated) {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/bin/zsh")
            proc.arguments = ["-c", self.generatedCommand]
            let pipe = Pipe()
            proc.standardOutput = pipe
            proc.standardError = pipe
            
            try? proc.run()
            proc.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "Command completed with no output."
            
            await MainActor.run {
                self.executionResult = output
                self.isExecuting = false
            }
        }
    }
}
