import SwiftUI
import AppKit

struct QuickLink: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let path: String
    let icon: String
}

class QuickLinksManager: ObservableObject {
    @Published var links: [QuickLink] = []
    private let storageKey = "juicer.quicklinks"
    
    init() {
        loadLinks()
        if links.isEmpty {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            links = [
                QuickLink(id: UUID(), name: "Xcode DerivedData", path: "\(home)/Library/Developer/Xcode/DerivedData", icon: "hammer.fill"),
                QuickLink(id: UUID(), name: "Applications Directory", path: "/Applications", icon: "apps.ipad"),
                QuickLink(id: UUID(), name: "User Downloads", path: "\(home)/Downloads", icon: "arrow.down.circle.fill")
            ]
            saveLinks()
        }
    }
    
    func loadLinks() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([QuickLink].self, from: data) {
            self.links = decoded
        }
    }
    
    func saveLinks() {
        if let data = try? JSONEncoder().encode(links) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    func addLink(name: String, path: String) {
        let expanded = NSString(string: path).expandingTildeInPath
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: expanded, isDirectory: &isDir)
        let isFolder = exists && isDir.boolValue
        let icon = isFolder ? "folder.fill" : "doc.fill"
        let newLink = QuickLink(id: UUID(), name: name, path: path, icon: icon)
        self.links.append(newLink)
        saveLinks()
    }
    
    func removeLink(_ link: QuickLink) {
        self.links.removeAll { $0.id == link.id }
        saveLinks()
    }
}

struct dashboardview: View {
    @State private var totalDiskSpace: String = "Loading..."
    @State private var freeDiskSpace: String = "Loading..."
    @State private var usedDiskSpacePercentage: Double = 0.0
    @State private var macOSVersion: String = ProcessInfo.processInfo.operatingSystemVersionString
    
    @StateObject private var quickLinksManager = QuickLinksManager()
    @State private var isShowingAddLink = false
    @State private var newLinkName = ""
    @State private var newLinkPath = ""
    @AppStorage("juicer.dashboard.showVitals") private var showVitals = true
    @AppStorage("juicer.dashboard.showCuratedTools") private var showCuratedTools = true
    @AppStorage("juicer.dashboard.showBookmarks") private var showBookmarks = true
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Editorial Main Card
                editorialMainCard()
                
                // System Vitals & Recommendations grid
                if showVitals || showCuratedTools {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)], spacing: 20) {
                        if showVitals { vitalsCard() }
                        if showCuratedTools { curatedToolsCard() }
                    }
                }

                // Bookmarks & Quick Links Section
                if showBookmarks { bookmarksSection() }
            }
            .padding(24)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            updateDiskMetrics()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.action.addBookmark"))) { _ in
            isShowingAddLink = true
        }
        .sheet(isPresented: $isShowingAddLink) {
            addLinkSheet()
        }
    }
    
    // MARK: - Editorial Main Card (App Store Featured style)
    @ViewBuilder
    private func editorialMainCard() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("WELCOME COMPANION")
                .font(.caption2).bold()
                .foregroundStyle(.white.opacity(0.8))
                .tracking(1.5)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Juicer is ready.")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Your ultimate open-source macOS developer utility.")
                    .font(.title3).medium()
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            Text("Clean junk, strip Gatekeeper blocks, manage active local ports, explore drive usages, and discover packages in the Software Center.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(2)
                .frame(maxWidth: 550)
            
            HStack(spacing: 12) {
                Button(action: {
                    NotificationCenter.default.post(name: NSNotification.Name("juicer.nav.cacheCleaner"), object: nil)
                }) {
                    Text("Clean Caches")
                        .font(.body).bold()
                        .foregroundColor(.orange)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(20)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    NotificationCenter.default.post(name: NSNotification.Name("juicer.nav.appStore"), object: nil)
                }) {
                    Text("Browse Software Center")
                        .font(.body).bold()
                        .foregroundColor(.white)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(20)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
        }
        .padding(30)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.orange, Color.red, Color.pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    // MARK: - Vitals Card
    @ViewBuilder
    private func vitalsCard() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("System Vitals").font(.headline).foregroundStyle(.primary)
            
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.12), lineWidth: 10)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(usedDiskSpacePercentage))
                        .stroke(
                            LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(Angle(degrees: -90))
                    
                    Text("\(Int(usedDiskSpacePercentage * 100))%")
                        .font(.headline).bold()
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Disk Storage").bold()
                    Text("Free: \(freeDiskSpace)").font(.subheadline).foregroundStyle(.secondary)
                    Text("Total: \(totalDiskSpace)").font(.caption).foregroundStyle(.tertiary)
                    Text("OS: \(macOSVersion)").font(.caption).foregroundStyle(.tertiary).lineLimit(1)
                }
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.2))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.secondary.opacity(0.1), lineWidth: 1))
    }

    // MARK: - Curated Tools
    @ViewBuilder
    private func curatedToolsCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Discover Essential Tools").font(.headline).foregroundStyle(.primary)
            
            VStack(spacing: 8) {
                curatedToolRow(title: "App Uninstaller", desc: "Drag & drop cleaner companion", icon: "trash.fill", color: .red, dest: "juicer.nav.uninstaller")
                curatedToolRow(title: "Software Center", desc: "Browse Casks & Formulae", icon: "square.grid.3x3.fill", color: .purple, dest: "juicer.nav.appStore")
                curatedToolRow(title: "System Optimizer", desc: "Refresh cache databases & flush DNS", icon: "bolt.fill", color: .yellow, dest: "juicer.nav.systemOptimizer")
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.2))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.secondary.opacity(0.1), lineWidth: 1))
    }

    @ViewBuilder
    private func curatedToolRow(title: String, desc: String, icon: String, color: Color, dest: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.15)).frame(width: 32, height: 32)
                Image(systemName: icon).foregroundColor(color).font(.body)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).bold()
                Text(desc).font(.caption).foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("OPEN") {
                NotificationCenter.default.post(name: NSNotification.Name(dest), object: nil)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Bookmarks Section
    @ViewBuilder
    private func bookmarksSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Companion Shortcuts & Bookmarks")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Button(action: { isShowingAddLink = true }) {
                    Label("Add Shortcut", systemImage: "plus")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            if quickLinksManager.links.isEmpty {
                Text("No bookmarks added yet. Drop folders or files here to bookmark them.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.2))
                    .cornerRadius(8)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(quickLinksManager.links) { link in
                        QuickLinkCard(link: link, onNavigate: {
                            let expanded = NSString(string: link.path).expandingTildeInPath
                            NSWorkspace.shared.selectFile(expanded, inFileViewerRootedAtPath: "")
                            AppLogger.shared.log("Opened shortcut location: \(expanded)")
                        }, onDelete: {
                            quickLinksManager.removeLink(link)
                        })
                    }
                }
            }
        }
    }
    
    // MARK: - Add Link Sheet
    @ViewBuilder
    private func addLinkSheet() -> some View {
        VStack(spacing: 20) {
            Text("Add Bookmark Link")
                .font(.headline)
                .bold()
            
            Form {
                TextField("Shortcut Name:", text: $newLinkName)
                    .textFieldStyle(.roundedBorder)
                
                HStack {
                    TextField("Path (File or Folder):", text: $newLinkPath)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Browse...") {
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = true
                        panel.title = "Select File or Folder to Bookmark"
                        if panel.runModal() == .OK, let url = panel.url {
                            newLinkPath = url.path
                            if newLinkName.isEmpty {
                                newLinkName = url.lastPathComponent
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal)
            
            HStack {
                Spacer()
                Button("Cancel") {
                    isShowingAddLink = false
                    newLinkName = ""
                    newLinkPath = ""
                }
                .buttonStyle(.bordered)
                
                Button("Add Link") {
                    if !newLinkName.isEmpty && !newLinkPath.isEmpty {
                        quickLinksManager.addLink(name: newLinkName, path: newLinkPath)
                        isShowingAddLink = false
                        newLinkName = ""
                        newLinkPath = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newLinkName.isEmpty || newLinkPath.isEmpty)
            }
            .padding()
        }
        .frame(width: 420, height: 220)
        .padding()
    }
    
    private func updateDiskMetrics() {
        let fileManager = FileManager.default
        let path = "/"
        do {
            let values = try fileManager.attributesOfFileSystem(forPath: path)
            if let totalBytes = values[.systemSize] as? Int64,
               let freeBytes = values[.systemFreeSize] as? Int64 {
                let usedBytes = totalBytes - freeBytes
                
                let formatter = ByteCountFormatter()
                formatter.countStyle = .file
                formatter.allowedUnits = [.useGB, .useTB]
                
                totalDiskSpace = formatter.string(fromByteCount: totalBytes)
                freeDiskSpace = formatter.string(fromByteCount: freeBytes)
                usedDiskSpacePercentage = Double(usedBytes) / Double(totalBytes)
            }
        } catch {
            AppLogger.shared.log("Error reading disk metrics: \(error.localizedDescription)")
        }
    }
}

struct QuickLinkCard: View {
    let link: QuickLink
    let onNavigate: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: link.icon)
                .font(.title3)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(link.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(link.path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            if isHovered {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor).opacity(isHovered ? 0.6 : 0.3))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(isHovered ? 0.2 : 0.1), lineWidth: 1)
        )
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hover
            }
        }
        .onTapGesture {
            onNavigate()
        }
    }
}

extension Text {
    func medium() -> Text {
        self.fontWeight(.medium)
    }
}
