import SwiftUI
import AppKit

struct CreatorRepoItem: Identifiable {
    let id = UUID()
    let name: String
    let repository: String
    let category: String
    let description: String
    let iconName: String
    let themeColor: Color
    let tag: String?
    let language: String
    let starsCount: String
    let brewCommand: String?
}

struct creatorecosystemview: View {
    @State private var searchText = ""
    @State private var selectedCategoryFilter = "All"
    @State private var copiedRepo: String? = nil
    @State private var cloningRepo: String? = nil
    @State private var cloneStatusMessage: String? = nil
    @State private var cloneStatusColor: Color = .green
    @State private var lastClonedPath: String? = nil
    
    // Category expansion state
    @State private var expandedCategories: [String: Bool] = [
        "macOS Applications": true,
        "Developer Tooling & Homebrew Taps": true,
        "Extensions & Scripts": true,
        "GitHub Profile & Meta": true
    ]
    
    let allRepos: [CreatorRepoItem] = [
        // macOS Apps
        CreatorRepoItem(
            name: "Juicer",
            repository: "amfi-disable/Juicer",
            category: "macOS Applications",
            description: "The ultimate 14-studio macOS developer workbench, system cleaner, and companion suite.",
            iconName: "shippingbox.fill",
            themeColor: .orange,
            tag: "MAIN APP",
            language: "Swift / SwiftUI",
            starsCount: "v1.0.3",
            brewCommand: "brew install --cask juicer"
        ),
        CreatorRepoItem(
            name: "Brew-Ghost",
            repository: "amfi-disable/Brew-Ghost",
            category: "macOS Applications",
            description: "Automated ghost package finder, orphan formula scanner, and Homebrew cellar cleaner.",
            iconName: "ghost.fill",
            themeColor: .purple,
            tag: "TOP BREW",
            language: "Swift / Shell",
            starsCount: "v1.0.0",
            brewCommand: "brew install --cask brew-ghost"
        ),
        CreatorRepoItem(
            name: "OmniSuite",
            repository: "amfi-disable/OmniSuite",
            category: "macOS Applications",
            description: "Modular system productivity & developer workbench for high-efficiency macOS workflows.",
            iconName: "square.stack.3d.up.fill",
            themeColor: .blue,
            tag: "SYSTEM",
            language: "Swift / macOS",
            starsCount: "Latest",
            brewCommand: nil
        ),
        CreatorRepoItem(
            name: "PathDeck",
            repository: "amfi-disable/PathDeck",
            category: "macOS Applications",
            description: "Streamlined workspace path launcher, hotkey trigger, and directory navigator.",
            iconName: "square.grid.3x3.topleft.filled",
            themeColor: .teal,
            tag: "LAUNCHER",
            language: "Swift",
            starsCount: "Latest",
            brewCommand: nil
        ),
        
        // Tooling & Taps
        CreatorRepoItem(
            name: "homebrew-juicer",
            repository: "amfi-disable/homebrew-juicer",
            category: "Developer Tooling & Homebrew Taps",
            description: "Official Homebrew Cask tap repository for installing and updating Juicer via brew.",
            iconName: "mug.fill",
            themeColor: .cyan,
            tag: "CASK TAP",
            language: "Ruby",
            starsCount: "Tap",
            brewCommand: "brew tap amfi-disable/juicer"
        ),
        CreatorRepoItem(
            name: "homebrew-tap",
            repository: "amfi-disable/homebrew-tap",
            category: "Developer Tooling & Homebrew Taps",
            description: "Community Homebrew formula tap containing custom CLI tools and developer binaries.",
            iconName: "terminal.fill",
            themeColor: .cyan,
            tag: "FORMULA TAP",
            language: "Ruby",
            starsCount: "Tap",
            brewCommand: "brew tap amfi-disable/tap"
        ),
        
        // Extensions & Scripts
        CreatorRepoItem(
            name: "FMG",
            repository: "amfi-disable/FMG",
            category: "Extensions & Scripts",
            description: "Flight & map web extension for real-time telemetry and navigation overlays.",
            iconName: "puzzlepiece.extension.fill",
            themeColor: .green,
            tag: "EXTENSION",
            language: "JavaScript / Web",
            starsCount: "v1.0",
            brewCommand: nil
        ),
        CreatorRepoItem(
            name: "GeoFS-V3.9",
            repository: "amfi-disable/GeoFS-V3.9",
            category: "Extensions & Scripts",
            description: "Flight simulator script enhancements, autopilot tools, and HUD additions.",
            iconName: "airplane",
            themeColor: .blue,
            tag: "SCRIPT",
            language: "JavaScript",
            starsCount: "v3.9",
            brewCommand: nil
        ),
        CreatorRepoItem(
            name: "GimSell",
            repository: "amfi-disable/GimSell",
            category: "Extensions & Scripts",
            description: "Gimkit automation script for market trading and automated item inventory.",
            iconName: "cart.fill",
            themeColor: .yellow,
            tag: "AUTOMATION",
            language: "JavaScript",
            starsCount: "v1.0",
            brewCommand: nil
        ),
        
        // Profile & Meta
        CreatorRepoItem(
            name: "amfi-disable Profile",
            repository: "amfi-disable/amfi-disable",
            category: "GitHub Profile & Meta",
            description: "GitHub organization profile, README showcase, and community highlights.",
            iconName: "person.crop.circle.fill",
            themeColor: .pink,
            tag: "PROFILE",
            language: "Markdown",
            starsCount: "Org",
            brewCommand: nil
        )
    ]
    
    var categories: [String] {
        ["macOS Applications", "Developer Tooling & Homebrew Taps", "Extensions & Scripts", "GitHub Profile & Meta"]
    }
    
    var filterOptions: [String] {
        ["All", "macOS Applications", "Developer Tooling & Homebrew Taps", "Extensions & Scripts", "GitHub Profile & Meta"]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header Banner
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: [.orange, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 52, height: 52)
                    Image(systemName: "star.square.on.square.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text("Juicer Creator's Studio")
                            .font(.title2).bold()
                        
                        Text("10 REPOSITORIES")
                            .font(.system(size: 9, weight: .black))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.orange.opacity(0.18), in: Capsule())
                            .foregroundColor(.orange)
                    }
                    
                    Text("Explore, clone, install Homebrew taps, and manage open-source software by amfi-disable")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 10) {
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString("brew tap amfi-disable/juicer", forType: .string)
                        cloneStatusMessage = "Copied 'brew tap amfi-disable/juicer' to clipboard!"
                        cloneStatusColor = .cyan
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "mug.fill")
                            Text("Copy Tap")
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        if let url = URL(string: "https://github.com/amfi-disable") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.right.square.fill")
                            Text("GitHub Profile")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                }
            }
            .padding(20)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Search & Category Filter Bar
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    // Search Input
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Filter repositories by name, language, tag, or description...", text: $searchText)
                            .textFieldStyle(.plain)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(9)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }
                
                // Category Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filterOptions, id: \.self) { filter in
                            let isSelected = selectedCategoryFilter == filter
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedCategoryFilter = filter
                                }
                            }) {
                                Text(filterNameShort(filter))
                                    .font(.caption.weight(isSelected ? .bold : .medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 5)
                                    .background(isSelected ? Color.orange.opacity(0.2) : Color.secondary.opacity(0.08), in: Capsule())
                                    .overlay(Capsule().stroke(isSelected ? Color.orange.opacity(0.6) : Color.clear, lineWidth: 1))
                                    .foregroundColor(isSelected ? .orange : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Live Status Notification Banner if Cloning or Copying
            if let msg = cloneStatusMessage {
                HStack(spacing: 10) {
                    if cloningRepo != nil {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(cloneStatusColor)
                    }
                    Text(msg)
                        .font(.caption.bold())
                        .foregroundColor(cloneStatusColor)
                    
                    Spacer()
                    
                    if let path = lastClonedPath {
                        Button("Show in Finder") {
                            NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    Button(action: { cloneStatusMessage = nil; lastClonedPath = nil }) {
                        Image(systemName: "xmark").font(.caption2)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(cloneStatusColor.opacity(0.12))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Categorized Repositories List
            ScrollView {
                VStack(spacing: 18) {
                    let activeCategories = categories.filter { cat in
                        selectedCategoryFilter == "All" || selectedCategoryFilter == cat
                    }
                    
                    ForEach(activeCategories, id: \.self) { cat in
                        let catRepos = allRepos.filter { repo in
                            repo.category == cat &&
                            (searchText.isEmpty ||
                             repo.name.localizedCaseInsensitiveContains(searchText) ||
                             repo.description.localizedCaseInsensitiveContains(searchText) ||
                             repo.language.localizedCaseInsensitiveContains(searchText) ||
                             (repo.tag?.localizedCaseInsensitiveContains(searchText) ?? false))
                        }
                        
                        if !catRepos.isEmpty {
                            let isExpanded = expandedCategories[cat] ?? true
                            
                            VStack(spacing: 0) {
                                // Category Header Toggle Button
                                Button(action: {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                        expandedCategories[cat] = !isExpanded
                                    }
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: categoryIcon(for: cat))
                                            .font(.headline)
                                            .foregroundColor(categoryColor(for: cat))
                                            .frame(width: 26, height: 26)
                                            .background(categoryColor(for: cat).opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
                                        
                                        Text(cat)
                                            .font(.headline.bold())
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Text("\(catRepos.count) \(catRepos.count == 1 ? "repo" : "repos")")
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(categoryColor(for: cat).opacity(0.14), in: Capsule())
                                            .foregroundColor(categoryColor(for: cat))
                                        
                                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                            .font(.caption.bold())
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(14)
                                }
                                .buttonStyle(.plain)
                                
                                if isExpanded {
                                    Divider().padding(.horizontal, 14)
                                    
                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 330, maximum: 460), spacing: 14)], spacing: 14) {
                                        ForEach(catRepos) { repo in
                                            repoCard(repo: repo)
                                        }
                                    }
                                    .padding(14)
                                }
                            }
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.secondary.opacity(0.12), lineWidth: 1))
                        }
                    }
                }
                .padding(20)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func filterNameShort(_ filter: String) -> String {
        switch filter {
        case "Developer Tooling & Homebrew Taps": return "Developer Tools"
        case "GitHub Profile & Meta": return "Profile"
        default: return filter
        }
    }
    
    @ViewBuilder
    private func repoCard(repo: CreatorRepoItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: repo.iconName)
                    .font(.title3)
                    .foregroundColor(repo.themeColor)
                    .frame(width: 36, height: 36)
                    .background(repo.themeColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(repo.name)
                            .font(.headline.bold())
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        if let tag = repo.tag {
                            Text(tag)
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(repo.themeColor.opacity(0.18), in: Capsule())
                                .foregroundColor(repo.themeColor)
                        }
                    }
                    
                    Text(repo.repository)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(repo.starsCount)
                    .font(.caption2.bold())
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.12), in: Capsule())
            }
            
            Text(repo.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            Divider()
            
            // Controls Footer Bar
            HStack {
                HStack(spacing: 5) {
                    Circle()
                        .fill(repo.themeColor)
                        .frame(width: 8, height: 8)
                    Text(repo.language)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Brew Install Shortcut Button if available
                if let brew = repo.brewCommand {
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(brew, forType: .string)
                        cloneStatusMessage = "Copied '\(brew)' to clipboard!"
                        cloneStatusColor = repo.themeColor
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "terminal")
                            Text("Brew")
                        }
                        .font(.caption2.bold())
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                // Direct Git Clone to Directory
                Button(action: {
                    cloneRepoToFolder(repo: repo)
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.down.circle.fill")
                        Text(cloningRepo == repo.repository ? "Cloning..." : "Clone To...")
                    }
                    .font(.caption2.bold())
                }
                .buttonStyle(.bordered)
                .tint(repo.themeColor)
                .disabled(cloningRepo == repo.repository)
                
                // Open on GitHub Web
                Button(action: {
                    if let url = URL(string: "https://github.com/\(repo.repository)") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.up.right.square")
                        Text("Open")
                    }
                    .font(.caption2.bold())
                }
                .buttonStyle(.borderedProminent)
                .tint(repo.themeColor)
                .controlSize(.small)
            }
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(repo.themeColor.opacity(0.28), lineWidth: 1))
    }
    
    private func cloneRepoToFolder(repo: CreatorRepoItem) {
        let panel = NSOpenPanel()
        panel.title = "Select Folder to Clone \(repo.name) Into"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        
        if panel.runModal() == .OK, let targetDir = panel.url {
            cloningRepo = repo.repository
            cloneStatusMessage = "Cloning \(repo.repository) into \(targetDir.lastPathComponent)..."
            cloneStatusColor = .orange
            
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
                process.arguments = ["clone", "https://github.com/\(repo.repository).git"]
                process.currentDirectoryURL = targetDir
                
                do {
                    try process.run()
                    process.waitUntilExit()
                    
                    let clonedFolder = targetDir.appendingPathComponent(repo.name)
                    
                    DispatchQueue.main.async {
                        self.cloningRepo = nil
                        if process.terminationStatus == 0 {
                            self.cloneStatusMessage = "Successfully cloned \(repo.name)!"
                            self.cloneStatusColor = .green
                            self.lastClonedPath = clonedFolder.path
                        } else {
                            self.cloneStatusMessage = "Failed to clone repository. Make sure git is installed."
                            self.cloneStatusColor = .red
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.cloningRepo = nil
                        self.cloneStatusMessage = "Error running git clone: \(error.localizedDescription)"
                        self.cloneStatusColor = .red
                    }
                }
            }
        }
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "macOS Applications": return "laptopcomputer"
        case "Developer Tooling & Homebrew Taps": return "wrench.and.screwdriver.fill"
        case "Extensions & Scripts": return "puzzlepiece.extension.fill"
        default: return "network"
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "macOS Applications": return .orange
        case "Developer Tooling & Homebrew Taps": return .cyan
        case "Extensions & Scripts": return .green
        default: return .pink
        }
    }
}
