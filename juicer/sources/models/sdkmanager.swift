import Foundation

struct SDKRuntime: Identifiable, Hashable, Codable {
    var id: String { name }
    let name: String // e.g. "Node.js (nvm)", "Python (pyenv)", "Homebrew Node"
    let type: RuntimeType
    var installedVersions: [String]
    var activeVersion: String
    
    enum RuntimeType: String, Codable {
        case nodeNvm = "Node.js (nvm)"
        case nodeFnm = "Node.js (fnm)"
        case pythonPyenv = "Python (pyenv)"
        case rubyRbenv = "Ruby (rbenv)"
        case rubyRvm = "Ruby (rvm)"
        case rustRustup = "Rust (rustup)"
        case brewRuntime = "Homebrew Runtimes"
    }
}

class SDKManager: ObservableObject {
    @Published var runtimes: [SDKRuntime] = []
    @Published var isLoading = false
    
    func loadRuntimes() {
        self.isLoading = true
        self.runtimes = []
        
        Task.detached(priority: .userInitiated) {
            var discovered: [SDKRuntime] = []
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            
            // 1. Node.js (nvm)
            let nvmDir = "\(home)/.nvm/versions/node"
            if FileManager.default.fileExists(atPath: nvmDir),
               let versions = try? FileManager.default.contentsOfDirectory(atPath: nvmDir) {
                let installed = versions.filter { !$0.hasPrefix(".") }.sorted()
                if !installed.isEmpty {
                    let active = Self.runShellCommand("nvm current").trimmingCharacters(in: .whitespacesAndNewlines)
                    discovered.append(SDKRuntime(
                        name: "Node.js (nvm)",
                        type: .nodeNvm,
                        installedVersions: installed,
                        activeVersion: active.isEmpty ? (installed.last ?? "Unknown") : active
                    ))
                }
            }
            
            // 2. Node.js (fnm)
            let fnmDir = "\(home)/Library/Application Support/fnm/aliases"
            let fnmStateDir = "\(home)/.local/state/fnm/downloads"
            var fnmVersions: [String] = []
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: fnmStateDir) {
                fnmVersions = contents.filter { !$0.hasPrefix(".") }
            } else if let contents = try? FileManager.default.contentsOfDirectory(atPath: "\(home)/.fnm") {
                // Alternately check ~/.fnm path
                fnmVersions = contents.filter { !$0.hasPrefix(".") }
            }
            if !fnmVersions.isEmpty {
                let active = Self.runShellCommand("fnm current").trimmingCharacters(in: .whitespacesAndNewlines)
                discovered.append(SDKRuntime(
                    name: "Node.js (fnm)",
                    type: .nodeFnm,
                    installedVersions: fnmVersions.sorted(),
                    activeVersion: active.isEmpty ? "default" : active
                ))
            }
            
            // 3. Python (pyenv)
            let pyenvDir = "\(home)/.pyenv/versions"
            if FileManager.default.fileExists(atPath: pyenvDir),
               let versions = try? FileManager.default.contentsOfDirectory(atPath: pyenvDir) {
                let installed = versions.filter { !$0.hasPrefix(".") }.sorted()
                if !installed.isEmpty {
                    let active = Self.runShellCommand("pyenv global").trimmingCharacters(in: .whitespacesAndNewlines)
                    discovered.append(SDKRuntime(
                        name: "Python (pyenv)",
                        type: .pythonPyenv,
                        installedVersions: installed,
                        activeVersion: active.isEmpty ? (installed.last ?? "System") : active
                    ))
                }
            }
            
            // 4. Ruby (rbenv)
            let rbenvDir = "\(home)/.rbenv/versions"
            if FileManager.default.fileExists(atPath: rbenvDir),
               let versions = try? FileManager.default.contentsOfDirectory(atPath: rbenvDir) {
                let installed = versions.filter { !$0.hasPrefix(".") }.sorted()
                if !installed.isEmpty {
                    let active = Self.runShellCommand("rbenv global").trimmingCharacters(in: .whitespacesAndNewlines)
                    discovered.append(SDKRuntime(
                        name: "Ruby (rbenv)",
                        type: .rubyRbenv,
                        installedVersions: installed,
                        activeVersion: active.isEmpty ? (installed.last ?? "System") : active
                    ))
                }
            }
            
            // 5. Ruby (rvm)
            let rvmDir = "\(home)/.rvm/rubies"
            if FileManager.default.fileExists(atPath: rvmDir),
               let versions = try? FileManager.default.contentsOfDirectory(atPath: rvmDir) {
                let installed = versions.filter { !$0.hasPrefix(".") }.sorted()
                if !installed.isEmpty {
                    let active = Self.runShellCommand("rvm current").trimmingCharacters(in: .whitespacesAndNewlines)
                    discovered.append(SDKRuntime(
                        name: "Ruby (rvm)",
                        type: .rubyRvm,
                        installedVersions: installed,
                        activeVersion: active.isEmpty ? (installed.last ?? "System") : active
                    ))
                }
            }
            
            // 6. Rust (rustup)
            let rustupDir = "\(home)/.rustup/toolchains"
            if FileManager.default.fileExists(atPath: rustupDir),
               let versions = try? FileManager.default.contentsOfDirectory(atPath: rustupDir) {
                let installed = versions.filter { !$0.hasPrefix(".") }.sorted()
                if !installed.isEmpty {
                    let activeFull = Self.runShellCommand("rustup show active-toolchain").trimmingCharacters(in: .whitespacesAndNewlines)
                    let active = activeFull.components(separatedBy: .whitespaces).first ?? "stable"
                    discovered.append(SDKRuntime(
                        name: "Rust (rustup)",
                        type: .rustRustup,
                        installedVersions: installed,
                        activeVersion: active
                    ))
                }
            }
            
            // 7. Homebrew Runtimes (e.g. node@18, node@20, python@3.10)
            let brewOptDir = "/opt/homebrew/opt"
            let brewIntelOptDir = "/usr/local/opt"
            var brewVersions: [String] = []
            let targetDir = FileManager.default.fileExists(atPath: brewOptDir) ? brewOptDir : brewIntelOptDir
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: targetDir) {
                // Filter folder aliases like node@18, node@20, python@3.11, ruby@3.2
                for folder in contents {
                    if (folder.hasPrefix("node@") || folder.hasPrefix("python@") || folder.hasPrefix("ruby@")) && !folder.contains(".") {
                        brewVersions.append(folder)
                    }
                }
            }
            if !brewVersions.isEmpty {
                // Query active linked brew runtimes
                discovered.append(SDKRuntime(
                    name: "Homebrew Runtimes",
                    type: .brewRuntime,
                    installedVersions: brewVersions.sorted(),
                    activeVersion: "Link Managed"
                ))
            }
            
            await MainActor.run {
                self.runtimes = discovered
                self.isLoading = false
            }
        }
    }
    
    func switchVersion(for runtime: SDKRuntime, to version: String, completion: @escaping (Bool) -> Void) {
        AppLogger.shared.log("Switching \(runtime.name) active version to \(version)...")
        
        Task.detached(priority: .userInitiated) {
            let cmd: String
            switch runtime.type {
            case .nodeNvm:
                cmd = "source ~/.nvm/nvm.sh && nvm alias default \(version)"
            case .nodeFnm:
                cmd = "fnm default \(version)"
            case .pythonPyenv:
                cmd = "pyenv global \(version)"
            case .rubyRbenv:
                cmd = "rbenv global \(version)"
            case .rubyRvm:
                cmd = "rvm --default use \(version)"
            case .rustRustup:
                cmd = "rustup default \(version)"
            case .brewRuntime:
                // Extract base name e.g. "node" from "node@18"
                let baseName = version.components(separatedBy: "@").first ?? ""
                if !baseName.isEmpty {
                    cmd = "brew unlink \(baseName) && brew link --overwrite \(version)"
                } else {
                    cmd = "brew link --overwrite \(version)"
                }
            }
            
            let output = Self.runShellCommand(cmd)
            AppLogger.shared.log("Switch output: \(output)")
            
            await MainActor.run {
                self.loadRuntimes()
                completion(true)
            }
        }
    }
    
    // Command runner in login interactive context
    private static func runShellCommand(_ command: String) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        // Load shell configurations to initialize PATH for pyenv/nvm/rbenv/cargo
        process.arguments = ["-l", "-c", command]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } catch {
            return "Command execution failed: \(error.localizedDescription)"
        }
    }
}
