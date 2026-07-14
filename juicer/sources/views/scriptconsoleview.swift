import SwiftUI

struct ScriptTemplate: Identifiable {
    let id = UUID()
    let name: String
    let desc: String
    let code: String
    let icon: String
}

struct scriptconsoleview: View {
    @State private var scriptCode: String = ""
    @State private var consoleOutput: String = ""
    @State private var isRunning = false
    @State private var activeProcess: Process? = nil
    
    private let templates = [
        ScriptTemplate(name: "Flush DNS Cache", desc: "Flush macOS resolver and restart mDNSResponder service.", code: "dscacheutil -flushcache; sudo killall -HUP mDNSResponder\necho '✅ DNS Cache flushed successfully.'", icon: "network"),
        ScriptTemplate(name: "Free Inactive RAM", desc: "Forcibly purge memory caches using macOS system purge.", code: "sudo purge\necho '✅ RAM Purge completed.'", icon: "cpu"),
        ScriptTemplate(name: "Restart Finder & Dock", desc: "Kill and relaunch system Finder window and Dock workspace.", code: "killall Finder; killall Dock\necho '✅ Workspace restarted successfully.'", icon: "window.badge.ellipsis"),
        ScriptTemplate(name: "Clean Xcode Simulators", desc: "Reclaim space by erasing simulated device runtimes.", code: "xcrun simctl erase all\necho '✅ Simulator runtimes cleaned.'", icon: "iphone"),
        ScriptTemplate(name: "Prune Docker system", desc: "Reclaim space by removing stopped containers, unused networks/images.", code: "docker system prune -a --volumes -f\necho '✅ Docker cleanup finished.'", icon: "shippingbox.fill")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            headerBar()
            Divider()
            
            HSplitView {
                // Left Column: Templates selection
                VStack(alignment: .leading, spacing: 0) {
                    Text("Script Library")
                        .font(.headline)
                        .padding()
                    
                    Divider()
                    
                    List(templates) { template in
                        Button(action: { scriptCode = template.code }) {
                            HStack(spacing: 12) {
                                Image(systemName: template.icon)
                                    .font(.title3)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(template.name).font(.subheadline).bold()
                                    Text(template.desc).font(.caption2).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.inset)
                }
                .frame(minWidth: 260, idealWidth: 300, maxWidth: 340)
                
                // Right Column: Editor & Terminal Console
                VStack(spacing: 16) {
                    // Editor Panel
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Script Editor").font(.headline)
                            Spacer()
                            if isRunning {
                                Button("Cancel Action") {
                                    cancelExecution()
                                }
                                .buttonStyle(.bordered).tint(.red)
                            } else {
                                Button(action: runScript) {
                                    Label("Execute Script", systemImage: "play.fill")
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(scriptCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                        }
                        
                        TextEditor(text: $scriptCode)
                            .font(.system(.body, design: .monospaced))
                            .padding(8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
                            .frame(minHeight: 180)
                    }
                    
                    // Console Output Terminal
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Execution Console Logs").font(.headline)
                            Spacer()
                            Button("Clear Console") {
                                consoleOutput = ""
                            }
                            .buttonStyle(.bordered).controlSize(.small)
                        }
                        
                        ScrollViewReader { proxy in
                            ScrollView {
                                Text(consoleOutput.isEmpty ? "Ready to run. Execution outputs will stream here in real time." : consoleOutput)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(consoleOutput.isEmpty ? .secondary : .primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .id("console_bottom")
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
                            .onChange(of: consoleOutput) { _ in
                                proxy.scrollTo("console_bottom", anchor: .bottom)
                            }
                        }
                    }
                }
                .padding()
                .frame(minWidth: 400, maxWidth: .infinity)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    @ViewBuilder
    private func headerBar() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Custom Scripts Console")
                    .font(.title2).bold()
                Text("Write, review and execute shell script automations directly inside Juicer's isolated shell session.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Process Execution Runner
    
    private func runScript() {
        guard !isRunning else { return }
        isRunning = true
        consoleOutput = "⏳ Initializing shell execution session...\n\n"
        
        let commandStr = scriptCode
        
        Task.detached(priority: .userInitiated) {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/bin/sh")
            proc.arguments = ["-c", commandStr]
            
            let pipe = Pipe()
            proc.standardOutput = pipe
            proc.standardError = pipe
            
            await MainActor.run {
                self.activeProcess = proc
            }
            
            let fileHandle = pipe.fileHandleForReading
            fileHandle.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty else { return }
                if let str = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.consoleOutput += str
                    }
                }
            }
            
            do {
                try proc.run()
                proc.waitUntilExit()
                fileHandle.readabilityHandler = nil
                
                let exitStatus = proc.terminationStatus
                await MainActor.run {
                    self.isRunning = false
                    self.activeProcess = nil
                    if exitStatus == 0 {
                        self.consoleOutput += "\n✅ Script completed successfully (Exit Code 0).\n"
                    } else {
                        self.consoleOutput += "\n❌ Script terminated with non-zero exit code \(exitStatus).\n"
                    }
                }
            } catch {
                fileHandle.readabilityHandler = nil
                await MainActor.run {
                    self.isRunning = false
                    self.activeProcess = nil
                    self.consoleOutput += "\n❌ System execution error: \(error.localizedDescription)\n"
                }
            }
        }
    }
    
    private func cancelExecution() {
        activeProcess?.terminate()
        activeProcess = nil
        isRunning = false
        consoleOutput += "\n🛑 Execution aborted by user.\n"
    }
}
