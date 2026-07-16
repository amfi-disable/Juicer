import SwiftUI
import AppKit

struct TreemapItem: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let sizeBytes: Int64
    let isDirectory: Bool
    let rect: CGRect
    let depth: Int
    let color: Color
}

struct diskvisualizerview: View {
    @StateObject private var manager = DiskExplorerManager()
    @State private var pathInput: String = ""
    @State private var hoveredItem: TreemapItem?
    @State private var selectedItem: TreemapItem?
    @State private var showConfirmDelete = false

    var body: some View {
        VStack(spacing: 0) {
            headerSection()
            Divider()
            navigationBar()
            Divider()

            GeometryReader { geo in
                if manager.isScanning {
                    VStack(spacing: 12) {
                        ProgressView("Analyzing directories…").progressViewStyle(.circular)
                        Text(String(format: "Scan Progress: %.0f%%", manager.scanProgress * 100))
                            .font(.caption).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if manager.entries.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "square.grid.3x3.fill").font(.system(size: 40)).foregroundStyle(.secondary)
                        Text("Ready to Visualize").font(.headline).foregroundColor(.secondary)
                        Text("Browse or select a directory above to generate a treemap graph.").font(.subheadline).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    let items = layoutTreemap(entries: manager.entries, in: CGRect(origin: .zero, size: geo.size))
                    
                    ZStack(alignment: .topLeading) {
                        ForEach(items) { item in
                            treemapCell(item: item)
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            .background(Color(NSColor.underPageBackgroundColor).opacity(0.3))
            
            Divider()
            footerBar()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            pathInput = home
            manager.scanDirectory(path: home)
        }
        .alert("Move to Trash?", isPresented: $showConfirmDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Trash", role: .destructive) {
                if let item = selectedItem {
                    try? FileManager.default.removeItem(atPath: item.path)
                    selectedItem = nil
                    manager.scanDirectory(path: manager.currentPath)
                }
            }
        } message: {
            if let item = selectedItem {
                Text("Are you sure you want to move '\(item.name)' to the Trash?\nSize: \(formatBytes(item.sizeBytes))")
            }
        }
    }

    // MARK: - Header
    @ViewBuilder
    private func headerSection() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Disk Visualizer Space Lens")
                    .font(.title2).bold()
                Text("Treemap visualization. Larger blocks represent larger files/folders. Double-click directory cells to zoom in.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: { manager.scanDirectory(path: manager.currentPath) }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .disabled(manager.isScanning)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }

    // MARK: - Navigation Bar
    @ViewBuilder
    private func navigationBar() -> some View {
        HStack(spacing: 8) {
            Button(action: goUp) {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.bordered)
            .disabled(manager.currentPath == "/" || manager.currentPath.isEmpty || manager.isScanning)

            Button(action: {
                let home = FileManager.default.homeDirectoryForCurrentUser.path
                pathInput = home
                manager.scanDirectory(path: home)
            }) {
                Image(systemName: "house.fill")
            }
            .buttonStyle(.bordered)

            Image(systemName: "folder.fill").foregroundStyle(.secondary)
            TextField("Browse path…", text: $pathInput, onCommit: {
                manager.scanDirectory(path: pathInput)
            })
            .textFieldStyle(.roundedBorder)

            Button("Browse…") {
                let panel = NSOpenPanel()
                panel.canChooseFiles = false
                panel.canChooseDirectories = true
                panel.allowsMultipleSelection = false
                panel.directoryURL = URL(fileURLWithPath: manager.currentPath.isEmpty ?
                    FileManager.default.homeDirectoryForCurrentUser.path : manager.currentPath)
                if panel.runModal() == .OK, let url = panel.url {
                    pathInput = url.path
                    manager.scanDirectory(path: url.path)
                }
            }
            .buttonStyle(.bordered)

            Button("Visualize") {
                manager.scanDirectory(path: pathInput)
            }
            .buttonStyle(.borderedProminent)
            .disabled(pathInput.isEmpty || manager.isScanning)
        }
        .padding(.horizontal).padding(.vertical, 7)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.15))
    }

    // MARK: - Treemap Cell
    @ViewBuilder
    private func treemapCell(item: TreemapItem) -> some View {
        let isSelected = selectedItem?.id == item.id
        let isHovered = hoveredItem?.id == item.id
        
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(item.color)
            
            RoundedRectangle(cornerRadius: 4)
                .stroke(isSelected ? Color.white : (isHovered ? Color.white.opacity(0.5) : Color.black.opacity(0.15)),
                        lineWidth: isSelected ? 2.5 : 1)
            
            // Only draw text labels for cells that are large enough
            if item.rect.width > 55 && item.rect.height > 30 {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(formatBytes(item.sizeBytes))
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                }
                .padding(4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .frame(width: max(item.rect.width, 1), height: max(item.rect.height, 1))
        .offset(x: item.rect.origin.x, y: item.rect.origin.y)
        .onHover { inside in
            withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.8)) {
                hoveredItem = inside ? item : nil
            }
        }
        .onTapGesture(count: 2) {
            if item.isDirectory {
                pathInput = item.path
                manager.scanDirectory(path: item.path)
            }
        }
        .onTapGesture(count: 1) {
            selectedItem = item
        }
        .help("\(item.name) (\(formatBytes(item.sizeBytes)))")
    }

    // MARK: - Footer details bar
    @ViewBuilder
    private func footerBar() -> some View {
        HStack(spacing: 12) {
            if let item = selectedItem {
                Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name).bold().font(.subheadline)
                    Text(item.path).font(.caption2).foregroundColor(.secondary)
                        .lineLimit(1).truncationMode(.middle)
                }
                Spacer()
                
                Text(formatBytes(item.sizeBytes)).bold().font(.subheadline)
                
                Button(action: { NSWorkspace.shared.selectFile(item.path, inFileViewerRootedAtPath: "") }) {
                    Image(systemName: "arrow.up.forward.square").font(.subheadline)
                }
                .buttonStyle(.bordered)
                .help("Reveal in Finder")
                
                Button(action: { showConfirmDelete = true }) {
                    Image(systemName: "trash.fill").font(.subheadline).foregroundColor(.red)
                }
                .buttonStyle(.bordered)
                .help("Move to Trash")
            } else if let hover = hoveredItem {
                Image(systemName: hover.isDirectory ? "folder.fill" : "doc.fill")
                    .foregroundColor(.secondary)
                Text(hover.name).font(.subheadline)
                Text("(\(formatBytes(hover.sizeBytes)))").font(.caption).foregroundColor(.secondary)
                Spacer()
            } else {
                Text("Click a block to review metadata, double-click directories to zoom in.")
                    .font(.caption).foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
        .frame(height: 48)
    }

    // MARK: - Helpers
    private func goUp() {
        let url = URL(fileURLWithPath: manager.currentPath)
        let parent = url.deletingLastPathComponent().path
        pathInput = parent
        manager.scanDirectory(path: parent)
    }

    private func formatBytes(_ bytes: Int64) -> String {
        guard bytes >= 0 else { return "—" }
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f.string(fromByteCount: bytes)
    }

    // MARK: - Binary Space Partitioning Treemap Layout
    private func layoutTreemap(entries: [DiskEntry], in rect: CGRect, depth: Int = 0) -> [TreemapItem] {
        guard !entries.isEmpty && rect.width > 2 && rect.height > 2 else { return [] }
        
        if entries.count == 1 {
            let entry = entries.first!
            let color = getColorForType(entry: entry)
            return [TreemapItem(name: entry.name, path: entry.path, sizeBytes: entry.sizeBytes, isDirectory: entry.isDirectory, rect: rect, depth: depth, color: color)]
        }
        
        let sorted = entries.sorted { $0.sizeBytes > $1.sizeBytes }
        let totalSize = sorted.reduce(0) { $0 + $1.sizeBytes }
        
        var index = 0
        var runningSum: Int64 = 0
        let target = totalSize / 2
        
        for (i, entry) in sorted.enumerated() {
            runningSum += entry.sizeBytes
            index = i
            if runningSum >= target {
                break
            }
        }
        
        let leftGroup = Array(sorted[0...index])
        let rightGroup = Array(sorted[(index + 1)...])
        
        let leftSize = leftGroup.reduce(0) { $0 + $1.sizeBytes }
        let ratio = CGFloat(leftSize) / CGFloat(max(totalSize, 1))
        
        var leftRect = CGRect.zero
        var rightRect = CGRect.zero
        
        // Split along the shorter axis of the block to maintain aspect ratio
        if rect.width > rect.height {
            let splitWidth = rect.width * ratio
            leftRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: splitWidth, height: rect.height)
            rightRect = CGRect(x: rect.origin.x + splitWidth, y: rect.origin.y, width: rect.width - splitWidth, height: rect.height)
        } else {
            let splitHeight = rect.height * ratio
            leftRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.width, height: splitHeight)
            rightRect = CGRect(x: rect.origin.x, y: rect.origin.y + splitHeight, width: rect.width, height: rect.height - splitHeight)
        }
        
        var results: [TreemapItem] = []
        results.append(contentsOf: layoutTreemap(entries: leftGroup, in: leftRect.insetBy(dx: 0.5, dy: 0.5), depth: depth + 1))
        results.append(contentsOf: layoutTreemap(entries: rightGroup, in: rightRect.insetBy(dx: 0.5, dy: 0.5), depth: depth + 1))
        return results
    }

    private func getColorForType(entry: DiskEntry) -> Color {
        if entry.isDirectory {
            return .blue.opacity(0.65)
        }
        let ext = (entry.name as NSString).pathExtension.lowercased()
        switch ext {
        case "mp4", "mkv", "avi", "mov", "mp3", "wav", "flac":
            return .pink.opacity(0.8)
        case "swift", "go", "py", "kt", "rs", "js", "ts", "html", "css", "cpp", "h", "json", "yml", "yaml":
            return .teal.opacity(0.8)
        case "zip", "tar", "gz", "rar", "7z", "dmg", "pkg":
            return .orange.opacity(0.8)
        case "png", "jpg", "jpeg", "gif", "svg", "heic", "webp":
            return .purple.opacity(0.8)
        default:
            return .secondary.opacity(0.6)
        }
    }
}
