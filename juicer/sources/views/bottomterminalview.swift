import SwiftUI

struct TerminalLine: Identifiable {
    let id = UUID()
    let text: String
    let isCommand: Bool
}

struct bottomterminalview: View {
    @ObservedObject var dirManager = WorkspaceDirectoryManager.shared
    @State private var commandInput: String = ""
    @State private var terminalLines: [TerminalLine] = [
        TerminalLine(text: "juicer terminal v1.0.0", isCommand: false),
        TerminalLine(text: "type 'help' for available commands. synced with active workspace folders.", isCommand: false)
    ]
    @State private var commandHistory: [String] = []
    @State private var historyIndex = -1
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with title and collapse button
            HStack {
                Image(systemName: "terminal.fill")
                    .foregroundColor(.accentColor)
                Text("juicer embedded terminal")
                    .font(.caption).bold()
                Spacer()
                Text(promptPath())
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: {
                    NotificationCenter.default.post(name: Notification.Name("juicer.toggleTerminal"), object: nil)
                }) {
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Terminal Output ScrollView
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(terminalLines) { line in
                            Text(line.text)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(line.isCommand ? .accentColor : .primary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(8)
                }
                .background(Color.black.opacity(0.85))
                .onChange(of: terminalLines.count) { _ in
                    if let last = terminalLines.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            
            Divider()
            
            // Terminal Input Prompt
            HStack(spacing: 4) {
                Text("\(promptPath()) $")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.green)
                
                TextField("", text: $commandInput)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white)
                    .onSubmit(executeCommand)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.black)
        }
        .frame(height: 180)
    }
    
    private func promptPath() -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if dirManager.currentDirectory == home {
            return "~"
        } else if dirManager.currentDirectory.hasPrefix(home) {
            return "~" + dirManager.currentDirectory.dropFirst(home.count)
        }
        return dirManager.currentDirectory
    }
    
    private func executeCommand() {
        let trimmed = commandInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        terminalLines.append(TerminalLine(text: "\(promptPath()) $ \(trimmed)", isCommand: true))
        commandHistory.append(trimmed)
        historyIndex = commandHistory.count
        commandInput = ""
        
        let args = trimmed.components(separatedBy: .whitespaces)
        let cmd = args[0]
        
        if cmd == "clear" {
            terminalLines = []
            return
        }
        
        if cmd == "help" {
            terminalLines.append(TerminalLine(text: "available commands: cd, clear, pwd, git, ls, echo, help or any shell command.", isCommand: false))
            return
        }
        
        if cmd == "cd" {
            let target: String
            if args.count > 1 {
                let pathArg = args[1]
                if pathArg == "~" {
                    target = FileManager.default.homeDirectoryForCurrentUser.path
                } else if pathArg.hasPrefix("/") {
                    target = pathArg
                } else {
                    target = URL(fileURLWithPath: dirManager.currentDirectory).appendingPathComponent(pathArg).standardized.path
                }
            } else {
                target = FileManager.default.homeDirectoryForCurrentUser.path
            }
            
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: target, isDirectory: &isDir), isDir.boolValue {
                dirManager.currentDirectory = target
            } else {
                terminalLines.append(TerminalLine(text: "cd: no such file or directory: \(args.count > 1 ? args[1] : "")", isCommand: false))
            }
            return
        }
        
        // Execute arbitrary command via zsh
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-c", "source ~/.zshrc; " + trimmed]
            process.currentDirectoryURL = URL(fileURLWithPath: dirManager.currentDirectory)
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            
            do {
                try process.run()
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                
                let output = String(data: outputData, encoding: .utf8) ?? ""
                let error = String(data: errorData, encoding: .utf8) ?? ""
                
                DispatchQueue.main.async {
                    if !output.isEmpty {
                        self.terminalLines.append(TerminalLine(text: output.trimmingCharacters(in: .whitespacesAndNewlines), isCommand: false))
                    }
                    if !error.isEmpty {
                        self.terminalLines.append(TerminalLine(text: error.trimmingCharacters(in: .whitespacesAndNewlines), isCommand: false))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.terminalLines.append(TerminalLine(text: "error executing command: \(error.localizedDescription)", isCommand: false))
                }
            }
        }
    }
}
