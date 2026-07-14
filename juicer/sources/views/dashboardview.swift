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
        let isFolder = (try? FileManager.default.attributesOfItem(atPath: expanded)[.fileType] as? FileAttributeType) == .typeDirectory
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
    
    // Add Link Sheet states
    @State private var isShowingAddLink = false
    @State private var newLinkName = ""
    @State private var newLinkPath = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // Welcome Banner
                VStack(alignment: .leading, spacing: 8) {
                    Text("juicer")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("The Ultimate Open-Source macOS Developer Utility")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                Divider()
                
                // System Summary Card
                VStack(alignment: .leading, spacing: 20) {
                    Text("System Storage")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 30) {
                        // Circular Progress
                        ZStack {
                            Circle()
                                .stroke(Color.secondary.opacity(0.15), lineWidth: 16)
                                .frame(width: 120, height: 120)
                            
                            Circle()
                                .trim(from: 0.0, to: CGFloat(usedDiskSpacePercentage))
                                .stroke(
                                    LinearGradient(
                                        colors: [.red, .orange],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                                )
                                .frame(width: 120, height: 120)
                                .rotationEffect(Angle(degrees: -90))
                            
                            VStack(spacing: 4) {
                                Text("\(Int(usedDiskSpacePercentage * 100))%")
                                    .font(.title2)
                                    .bold()
                                Text("Used")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Circle().fill(Color.orange).frame(width: 10, height: 10)
                                Text("Free Space: \(freeDiskSpace)")
                                    .font(.body)
                            }
                            HStack {
                                Circle().fill(Color.red).frame(width: 10, height: 10)
                                Text("Total Capacity: \(totalDiskSpace)")
                                    .font(.body)
                            }
                            HStack {
                                Circle().fill(Color.blue).frame(width: 10, height: 10)
                                Text("macOS Version: \(macOSVersion)")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                    )
                }
                
                // Quick Bookmarks & Links Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Bookmarks & Quick Links")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Button(action: { isShowingAddLink = true }) {
                            Label("Add Bookmark", systemImage: "plus")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    if quickLinksManager.links.isEmpty {
                        Text("No quick links added yet. Use the '+' button to add custom folders or files.")
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
                
                // Features Grid
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Tools")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        FeatureCard(
                            title: "App Uninstaller",
                            description: "Completely remove any application and all its hidden support files, logs, and preferences.",
                            icon: "trash.fill",
                            color: .red
                        )
                        FeatureCard(
                            title: "Orphan Finder",
                            description: "Detect and sweep away orphaned directories from apps that are no longer installed on your Mac.",
                            icon: "folder.badge.minus",
                            color: .orange
                        )
                        FeatureCard(
                            title: "Developer Caches",
                            description: "Instantly reclaim gigabytes by cleaning DerivedData, packages, caches, and unused docker images.",
                            icon: "hammer.fill",
                            color: .blue
                        )
                        FeatureCard(
                            title: "System Tweaks",
                            description: "Speed up Dock animations, key repeat rate, Finder features, and customize screenshooting.",
                            icon: "slider.horizontal.3",
                            color: .green
                        )
                    }
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
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

struct FeatureCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        )
    }
}
