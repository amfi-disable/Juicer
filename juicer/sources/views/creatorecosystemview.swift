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
}

struct creatorecosystemview: View {
    @State private var searchText = ""
    @State private var copiedRepo: String? = nil
    
    let allRepos: [CreatorRepoItem] = [
        // macOS Apps
        CreatorRepoItem(
            name: "Juicer",
            repository: "amfi-disable/Juicer",
            category: "macOS Applications",
            description: "The ultimate all-in-one macOS developer suite, system cleaner, and companion studio.",
            iconName: "shippingbox.fill",
            themeColor: .orange,
            tag: "MAIN APP",
            language: "Swift / SwiftUI",
            starsCount: "v1.0.2"
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
            starsCount: "v1.0.0"
        ),
        CreatorRepoItem(
            name: "OmniSuite",
            repository: "amfi-disable/OmniSuite",
            category: "macOS Applications",
            description: "Modular system productivity & developer workbench for high-efficiency workflows.",
            iconName: "square.stack.3d.up.fill",
            themeColor: .blue,
            tag: "SYSTEM",
            language: "Swift / macOS",
            starsCount: "Latest"
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
            starsCount: "Latest"
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
            starsCount: "Tap"
        ),
        CreatorRepoItem(
            name: "homebrew-tap",
            repository: "amfi-disable/homebrew-tap",
            category: "Developer Tooling & Homebrew Taps",
            description: "Community Homebrew formula tap containing custom CLI tools and binaries.",
            iconName: "terminal.fill",
            themeColor: .cyan,
            tag: "FORMULA TAP",
            language: "Ruby",
            starsCount: "Tap"
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
            starsCount: "v1.0"
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
            starsCount: "v3.9"
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
            starsCount: "v1.0"
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
            starsCount: "Org"
        )
    ]
    
    var categories: [String] {
        ["macOS Applications", "Developer Tooling & Homebrew Taps", "Extensions & Scripts", "GitHub Profile & Meta"]
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
                        Text("Creator Ecosystem Repositories")
                            .font(.title2).bold()
                        
                        Text("10 REPOS")
                            .font(.system(size: 9, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.18), in: Capsule())
                            .foregroundColor(.accentColor)
                    }
                    
                    Text("Explore, star, and clone repositories by amfi-disable")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
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
            .padding(20)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Filter creator repositories by name, language, or description...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 6)
            
            // Categorized Dropdown List
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(categories, id: \.self) { cat in
                        let catRepos = allRepos.filter { repo in
                            repo.category == cat &&
                            (searchText.isEmpty ||
                             repo.name.localizedCaseInsensitiveContains(searchText) ||
                             repo.description.localizedCaseInsensitiveContains(searchText) ||
                             repo.language.localizedCaseInsensitiveContains(searchText))
                        }
                        
                        if !catRepos.isEmpty {
                            DisclosureGroup(isExpanded: .constant(true)) {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 320, maximum: 440), spacing: 14)], spacing: 14) {
                                    ForEach(catRepos) { repo in
                                        repoCard(repo: repo)
                                    }
                                }
                                .padding(.top, 10)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: categoryIcon(for: cat))
                                        .font(.headline)
                                        .foregroundColor(categoryColor(for: cat))
                                    Text(cat)
                                        .font(.headline.bold())
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("\(catRepos.count) \(catRepos.count == 1 ? "repo" : "repos")")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(categoryColor(for: cat).opacity(0.14), in: Capsule())
                                        .foregroundColor(categoryColor(for: cat))
                                }
                                .padding(.vertical, 4)
                            }
                            .padding(14)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.6), in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.secondary.opacity(0.12), lineWidth: 1))
                        }
                    }
                }
                .padding(20)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    @ViewBuilder
    private func repoCard(repo: CreatorRepoItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: repo.iconName)
                    .font(.title3)
                    .foregroundColor(repo.themeColor)
                    .frame(width: 34, height: 34)
                    .background(repo.themeColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(repo.name)
                            .font(.headline.bold())
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        if let tag = repo.tag {
                            Text(tag)
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
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
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12), in: Capsule())
            }
            
            Text(repo.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            Divider()
            
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(repo.themeColor)
                        .frame(width: 8, height: 8)
                    Text(repo.language)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    let cmd = "git clone https://github.com/\(repo.repository).git"
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(cmd, forType: .string)
                    withAnimation {
                        copiedRepo = repo.repository
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        if copiedRepo == repo.repository { copiedRepo = nil }
                    }
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: copiedRepo == repo.repository ? "checkmark" : "doc.on.doc")
                        Text(copiedRepo == repo.repository ? "Copied!" : "Clone")
                    }
                    .font(.caption2.bold())
                }
                .buttonStyle(.bordered)
                .tint(copiedRepo == repo.repository ? .green : .secondary)
                
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
            }
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(repo.themeColor.opacity(0.3), lineWidth: 1))
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
