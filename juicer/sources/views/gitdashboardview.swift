import SwiftUI
import AppKit

struct gitdashboardview: View {
    @StateObject private var manager = GitRepositoryManager()
    @State private var commitMessage = ""
    @State private var conventionalPrefix = "feat"
    @State private var showNewBranchSheet = false
    @State private var newBranchName = ""
    @State private var selectedTab = "Staging"
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar & Repo Selector
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "arrow.triangle.pull")
                            .font(.title2)
                            .foregroundStyle(Color.accentColor)
                        Text("Juicer Git Studio")
                            .font(.title2)
                            .bold()
                    }
                    
                    if !manager.repoPath.isEmpty {
                        Text(manager.repoPath)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Current Branch Badge & Switcher
                Menu {
                    Section("Branches") {
                        ForEach(manager.branches) { branch in
                            Button(action: { manager.checkoutBranch(name: branch.name) }) {
                                HStack {
                                    if branch.isCurrent {
                                        Image(systemName: "checkmark")
                                    }
                                    Text(branch.name)
                                }
                            }
                        }
                    }
                    Divider()
                    Button("New Branch...") { showNewBranchSheet = true }
                } label: {
                    Label(manager.currentBranch.isEmpty ? "No Repo" : manager.currentBranch, systemImage: "line.horizontal.3.decrease")
                }
                .menuStyle(.borderlessButton)
                .buttonStyle(.bordered)
                
                Button("Open Repo...") {
                    let panel = NSOpenPanel()
                    panel.canChooseDirectories = true
                    panel.canChooseFiles = false
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK, let url = panel.url {
                        WorkspaceDirectoryManager.shared.currentDirectory = url.path
                    }
                }
                .buttonStyle(.bordered)
                
                Button(action: { manager.loadRepositoryState() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(manager.isLoading)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            
            Divider()
            
            // View Mode Switcher Toolbar
            HStack {
                Picker("", selection: $selectedTab) {
                    Text("Staging & Commit (\(manager.statusFiles.count))").tag("Staging")
                    Text("Commit History (\(manager.recentCommits.count))").tag("History")
                    Text("Branches (\(manager.branches.count))").tag("Branches")
                }
                .pickerStyle(.segmented)
                .frame(width: 380)
                
                Spacer()
            }
            .padding()
            
            Divider()
            
            // Main Workspace View
            if manager.repoPath.isEmpty || !manager.errorMessage.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.gearshape")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text(manager.errorMessage.isEmpty ? "Select a Git Repository to Begin" : manager.errorMessage)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Button("Open Git Repository") {
                        let panel = NSOpenPanel()
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = false
                        if panel.runModal() == .OK, let url = panel.url {
                            WorkspaceDirectoryManager.shared.currentDirectory = url.path
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if selectedTab == "Staging" {
                stagingWorkbenchView()
            } else if selectedTab == "History" {
                commitHistoryView()
            } else {
                branchesListView()
            }
        }
        .sheet(isPresented: $showNewBranchSheet) {
            VStack(spacing: 16) {
                Text("Create New Git Branch")
                    .font(.headline)
                TextField("Branch Name (e.g. feature/auth-flow)", text: $newBranchName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)
                HStack {
                    Button("Cancel") { showNewBranchSheet = false }
                    Button("Create & Checkout") {
                        if !newBranchName.isEmpty {
                            manager.createBranch(name: newBranchName)
                            newBranchName = ""
                            showNewBranchSheet = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
        }
        .onAppear {
            let activeDir = WorkspaceDirectoryManager.shared.currentDirectory
            if FileManager.default.fileExists(atPath: "\(activeDir)/.git") {
                manager.openRepository(at: activeDir)
            }
        }
        .onReceive(WorkspaceDirectoryManager.shared.$currentDirectory) { newDir in
            guard !newDir.isEmpty else { return }
            if manager.repoPath != newDir && FileManager.default.fileExists(atPath: "\(newDir)/.git") {
                manager.openRepository(at: newDir)
            }
        }
    }
    
    // MARK: - Staging Workbench
    @ViewBuilder
    private func stagingWorkbenchView() -> some View {
        HSplitView {
            // Left: File Changes & Staging List
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Working Tree Changes")
                        .font(.headline)
                    Spacer()
                    Button("Stage All") { manager.stageAll() }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    Button("Unstage All") { manager.unstageAll() }
                        .buttonStyle(.bordered)
                        .font(.caption)
                }
                .padding()
                
                Divider()
                
                if manager.statusFiles.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.green)
                        Text("Working Tree Clean")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(manager.statusFiles) { file in
                        HStack {
                            Toggle("", isOn: Binding(
                                get: { file.isStaged },
                                set: { val in
                                    if val {
                                        manager.stageFile(path: file.path)
                                    } else {
                                        manager.unstageFile(path: file.path)
                                    }
                                }
                            ))
                            .labelsHidden()
                            
                            Text(file.isUntracked ? "?" : (file.statusX != "." ? file.statusX : file.statusY))
                                .font(.caption.monospaced().bold())
                                .foregroundStyle(file.isUntracked ? Color.blue : (file.isStaged ? Color.green : Color.orange))
                                .frame(width: 20)
                            
                            Text(file.path)
                                .font(.system(.body, design: .monospaced))
                                .lineLimit(1)
                            
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                    .listStyle(.inset)
                }
            }
            .frame(minWidth: 320)
            
            // Right: Commit Studio
            VStack(alignment: .leading, spacing: 12) {
                Text("Commit Changes")
                    .font(.headline)
                
                HStack {
                    Picker("Type:", selection: $conventionalPrefix) {
                        Text("feat:").tag("feat")
                        Text("fix:").tag("fix")
                        Text("docs:").tag("docs")
                        Text("refactor:").tag("refactor")
                        Text("test:").tag("test")
                        Text("chore:").tag("chore")
                    }
                    .frame(width: 130)
                    
                    TextField("Summary message...", text: $commitMessage)
                        .textFieldStyle(.roundedBorder)
                }
                
                HStack {
                    Spacer()
                    Button("Commit (\(manager.statusFiles.filter { $0.isStaged }.count) staged)") {
                        let fullMsg = "\(conventionalPrefix): \(commitMessage)"
                        manager.createCommit(message: fullMsg) { _ in
                            commitMessage = ""
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(commitMessage.trimmingCharacters(in: .whitespaces).isEmpty || manager.statusFiles.filter { $0.isStaged }.isEmpty)
                }
                
                Spacer()
            }
            .padding()
            .frame(minWidth: 300)
        }
    }
    
    // MARK: - Commit History View
    @ViewBuilder
    private func commitHistoryView() -> some View {
        List(manager.recentCommits) { commit in
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: commit.isHead ? "circle.fill" : "circle")
                    .font(.caption)
                    .foregroundStyle(commit.isHead ? Color.accentColor : Color.secondary)
                    .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(commit.message)
                            .font(.headline)
                        Spacer()
                        Text(commit.shortHash)
                            .font(.system(.caption, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(4)
                    }
                    
                    HStack(spacing: 12) {
                        Text(commit.author)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(commit.date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .listStyle(.inset)
    }
    
    // MARK: - Branches View
    @ViewBuilder
    private func branchesListView() -> some View {
        List(manager.branches) { branch in
            HStack {
                Image(systemName: branch.isRemote ? "cloud" : "arrow.triangle.branch")
                    .foregroundStyle(branch.isCurrent ? Color.accentColor : Color.secondary)
                    .frame(width: 24)
                
                Text(branch.name)
                    .font(.headline)
                    .foregroundStyle(branch.isCurrent ? Color.accentColor : Color.primary)
                
                if branch.isCurrent {
                    Text("HEAD")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.2))
                        .foregroundStyle(Color.accentColor)
                        .cornerRadius(4)
                }
                
                Spacer()
                
                if let upstream = branch.upstream {
                    Text("tracking \(upstream)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if !branch.isCurrent {
                    Button("Checkout") {
                        manager.checkoutBranch(name: branch.name)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.vertical, 4)
        }
        .listStyle(.inset)
    }
}
