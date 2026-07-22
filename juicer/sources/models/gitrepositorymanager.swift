import Foundation
import Combine

struct GitStatusFile: Identifiable, Hashable {
    var id: String { path }
    let path: String
    let statusX: String // Staged status
    let statusY: String // Unstaged status
    let isStaged: Bool
    let isUntracked: Bool
}

struct GitCommitItem: Identifiable, Hashable {
    var id: String { hash }
    let hash: String
    let shortHash: String
    let author: String
    let email: String
    let date: String
    let message: String
    let parentHashes: [String]
    let isHead: Bool
}

struct GitBranchItem: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let isCurrent: Bool
    let isRemote: Bool
    let upstream: String?
}

class GitRepositoryManager: ObservableObject {
    @Published var repoPath: String = ""
    @Published var currentBranch: String = ""
    @Published var statusFiles: [GitStatusFile] = []
    @Published var recentCommits: [GitCommitItem] = []
    @Published var branches: [GitBranchItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String = ""
    
    private var fileWatcher: DispatchSourceFileSystemObject?
    
    init(repoPath: String = "") {
        if !repoPath.isEmpty {
            self.openRepository(at: repoPath)
        }
    }
    
    func openRepository(at path: String) {
        self.repoPath = path
        self.loadRepositoryState()
        self.startFileWatcher()
    }
    
    func loadRepositoryState() {
        guard !repoPath.isEmpty, FileManager.default.fileExists(atPath: "\(repoPath)/.git") else {
            self.errorMessage = "Not a valid Git repository."
            return
        }
        
        self.isLoading = true
        self.errorMessage = ""
        
        Task.detached(priority: .userInitiated) {
            let branch = self.runGitCommand(["rev-parse", "--abbrev-ref", "HEAD"]).trimmingCharacters(in: .whitespacesAndNewlines)
            let statusOutput = self.runGitCommand(["status", "--porcelain=v2", "--branch"])
            let logOutput = self.runGitCommand(["log", "-n", "50", "--pretty=format:%H|%h|%an|%ae|%ar|%s|%P"])
            let branchOutput = self.runGitCommand(["branch", "-a", "--format=%(HEAD)|%(refname:short)|%(upstream:short)"])
            
            let parsedStatus = self.parsePorcelainV2(statusOutput)
            let parsedCommits = self.parseCommitLog(logOutput)
            let parsedBranches = self.parseBranches(branchOutput)
            
            await MainActor.run {
                self.currentBranch = branch.isEmpty ? "HEAD (detached)" : branch
                self.statusFiles = parsedStatus
                self.recentCommits = parsedCommits
                self.branches = parsedBranches
                self.isLoading = false
            }
        }
    }
    
    func stageFile(path: String) {
        runGitCommandAsync(["add", path]) { self.loadRepositoryState() }
    }
    
    func unstageFile(path: String) {
        runGitCommandAsync(["restore", "--staged", path]) { self.loadRepositoryState() }
    }
    
    func stageAll() {
        runGitCommandAsync(["add", "-A"]) { self.loadRepositoryState() }
    }
    
    func unstageAll() {
        runGitCommandAsync(["restore", "--staged", "."]) { self.loadRepositoryState() }
    }
    
    func createCommit(message: String, completion: @escaping (Bool) -> Void) {
        guard !message.isEmpty else { completion(false); return }
        runGitCommandAsync(["commit", "-m", message]) {
            self.loadRepositoryState()
            completion(true)
        }
    }
    
    func checkoutBranch(name: String) {
        runGitCommandAsync(["checkout", name]) { self.loadRepositoryState() }
    }
    
    func createBranch(name: String) {
        runGitCommandAsync(["checkout", "-b", name]) { self.loadRepositoryState() }
    }
    
    // MARK: - Git Command Runner
    private func runGitCommand(_ args: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", repoPath] + args
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
    
    private func runGitCommandAsync(_ args: [String], completion: @escaping () -> Void) {
        Task.detached(priority: .userInitiated) {
            _ = self.runGitCommand(args)
            await MainActor.run {
                completion()
            }
        }
    }
    
    // MARK: - Parsers
    private func parsePorcelainV2(_ output: String) -> [GitStatusFile] {
        var results: [GitStatusFile] = []
        let lines = output.components(separatedBy: "\n")
        for line in lines {
            let parts = line.components(separatedBy: " ")
            if parts.first == "1" || parts.first == "2" {
                // Format: 1 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <path>
                if parts.count >= 9 {
                    let xy = parts[1]
                    let path = parts[8...].joined(separator: " ")
                    let x = String(xy.prefix(1))
                    let y = String(xy.suffix(1))
                    let staged = x != "."
                    results.append(GitStatusFile(path: path, statusX: x, statusY: y, isStaged: staged, isUntracked: false))
                }
            } else if parts.first == "?" {
                // Untracked format: ? <path>
                if parts.count >= 2 {
                    let path = parts[1...].joined(separator: " ")
                    results.append(GitStatusFile(path: path, statusX: "?", statusY: "?", isStaged: false, isUntracked: true))
                }
            }
        }
        return results
    }
    
    private func parseCommitLog(_ output: String) -> [GitCommitItem] {
        var results: [GitCommitItem] = []
        let lines = output.components(separatedBy: "\n")
        for (idx, line) in lines.enumerated() {
            let parts = line.components(separatedBy: "|")
            if parts.count >= 6 {
                let hash = parts[0]
                let shortHash = parts[1]
                let author = parts[2]
                let email = parts[3]
                let date = parts[4]
                let message = parts[5]
                let parents = parts.count >= 7 ? parts[6].components(separatedBy: " ").filter { !$0.isEmpty } : []
                
                results.append(GitCommitItem(
                    hash: hash,
                    shortHash: shortHash,
                    author: author,
                    email: email,
                    date: date,
                    message: message,
                    parentHashes: parents,
                    isHead: idx == 0
                ))
            }
        }
        return results
    }
    
    private func parseBranches(_ output: String) -> [GitBranchItem] {
        var results: [GitBranchItem] = []
        let lines = output.components(separatedBy: "\n")
        for line in lines {
            let parts = line.components(separatedBy: "|")
            guard parts.count >= 2 else { continue }
            let isHead = parts[0].trimmingCharacters(in: .whitespaces) == "*"
            let name = parts[1].trimmingCharacters(in: .whitespaces)
            let upstream = parts.count >= 3 && !parts[2].isEmpty ? parts[2] : nil
            guard !name.isEmpty else { continue }
            
            results.append(GitBranchItem(
                name: name,
                isCurrent: isHead,
                isRemote: name.hasPrefix("origin/") || name.hasPrefix("remotes/"),
                upstream: upstream
            ))
        }
        return results
    }
    
    private func startFileWatcher() {
        fileWatcher?.cancel()
        fileWatcher = nil
        
        let gitDirPath = "\(repoPath)/.git"
        let descriptor = open(gitDirPath, O_EVTONLY)
        guard descriptor >= 0 else { return }
        
        let watcher = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor, eventMask: .write, queue: .main)
        watcher.setEventHandler { [weak self] in
            self?.loadRepositoryState()
        }
        watcher.setCancelHandler {
            close(descriptor)
        }
        watcher.resume()
        self.fileWatcher = watcher
    }
}
