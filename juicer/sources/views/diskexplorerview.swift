import SwiftUI

struct diskexplorerview: View {
    @StateObject private var manager = DiskExplorerManager()
    @State private var pathInput: String = ""
    @State private var selectedEntry: DiskEntry?
    @State private var viewMode: ViewMode = .treemap
    @State private var selectedVolume: DiskVolume?

    enum ViewMode: String, CaseIterable {
        case treemap = "Bar Map"
        case list    = "File List"
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection()
            Divider()
            volumeBar()
            Divider()
            navigationBar()
            Divider()

            if manager.isScanning {
                scanningPlaceholder()
            } else if manager.entries.isEmpty && manager.errorMessage == nil {
                emptyStatePlaceholder()
            } else {
                contentView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            manager.loadVolumes()
            manager.scanDirectory(path: "")
        }
    }

    // MARK: - Header
    @ViewBuilder
    private func headerSection() -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Disk Explorer")
                    .font(.title2).bold()
                Text("Visualize disk usage across volumes and folders. Select a volume or browse any path.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()

            Picker("View", selection: $viewMode) {
                ForEach(ViewMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented).frame(width: 180)

            Button(action: { manager.scanDirectory(path: manager.currentPath) }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .disabled(manager.isScanning)
            .help("Rescan current path")
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }

    // MARK: - Volume Bar (all mounted disks including external)
    @ViewBuilder
    private func volumeBar() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(manager.volumes) { vol in
                    volumeCard(volume: vol)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.2))
        .frame(height: 84)
    }

    @ViewBuilder
    private func volumeCard(volume: DiskVolume) -> some View {
        let isSelected = selectedVolume?.id == volume.id
        Button(action: {
            selectedVolume = volume
            pathInput = volume.mountPoint
            manager.scanVolume(volume)
        }) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 5) {
                    Image(systemName: volume.icon)
                        .font(.caption).foregroundStyle(isSelected ? .white : .accentColor)
                    Text(volume.name)
                        .font(.caption).bold().lineLimit(1)
                        .foregroundStyle(isSelected ? .white : .primary)
                    if volume.isRemovable {
                        Image(systemName: "eject.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                    }
                }

                // Mini usage bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(isSelected ? Color.white.opacity(0.25) : Color.secondary.opacity(0.2))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(isSelected ? Color.white : volumeUsageColor(volume.usagePercent))
                            .frame(width: geo.size.width * volume.usagePercent)
                    }
                }
                .frame(height: 5)

                HStack {
                    Text(formatBytes(volume.usedBytes))
                        .font(.caption2)
                        .foregroundStyle(isSelected ? Color.white.opacity(0.85) : Color.secondary)
                    Spacer()
                    Text(formatBytes(volume.totalBytes))
                        .font(.caption2)
                        .foregroundStyle(isSelected ? Color.white.opacity(0.65) : Color.secondary.opacity(0.7))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(width: 160)
            .background(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.15), lineWidth: 1))
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Navigation Bar
    @ViewBuilder
    private func navigationBar() -> some View {
        HStack(spacing: 8) {
            // Back button
            Button(action: goUp) {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.bordered)
            .disabled(manager.currentPath == "/" || manager.currentPath.isEmpty || manager.isScanning)
            .help("Go up one level")

            // Home
            Button(action: {
                let home = FileManager.default.homeDirectoryForCurrentUser.path
                pathInput = home
                manager.scanDirectory(path: home)
            }) {
                Image(systemName: "house.fill")
            }
            .buttonStyle(.bordered)
            .help("Go to Home directory")

            // Breadcrumb path field
            Image(systemName: "folder.fill").foregroundStyle(.secondary)
            TextField("Enter path or pick a folder…", text: $pathInput, onCommit: {
                manager.scanDirectory(path: pathInput)
            })
            .textFieldStyle(.roundedBorder)

            // Browse button — shows folder AND disk picker
            Button("Browse…") {
                let panel = NSOpenPanel()
                panel.canChooseFiles = false
                panel.canChooseDirectories = true
                panel.allowsMultipleSelection = false
                panel.showsHiddenFiles = false
                // Allow navigation to volumes
                panel.directoryURL = URL(fileURLWithPath: manager.currentPath.isEmpty ?
                    FileManager.default.homeDirectoryForCurrentUser.path : manager.currentPath)
                panel.prompt = "Scan This Folder"
                panel.message = "Select a folder or navigate to a volume to scan:"
                if panel.runModal() == .OK, let url = panel.url {
                    pathInput = url.path
                    manager.scanDirectory(path: url.path)
                }
            }
            .buttonStyle(.bordered)

            // Go button
            Button("Go") {
                manager.scanDirectory(path: pathInput)
            }
            .buttonStyle(.borderedProminent)
            .disabled(pathInput.isEmpty || manager.isScanning)
        }
        .padding(.horizontal).padding(.vertical, 7)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.15))
    }

    // MARK: - Content
    @ViewBuilder
    private func contentView() -> some View {
        if let err = manager.errorMessage {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36)).foregroundStyle(.orange)
                Text(err).font(.headline).foregroundStyle(.secondary)
                Button("Go Home") {
                    let home = FileManager.default.homeDirectoryForCurrentUser.path
                    pathInput = home
                    manager.scanDirectory(path: home)
                }.buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            HSplitView {
                // Left: main content
                VStack(spacing: 0) {
                    if viewMode == .treemap {
                        treemapView()
                    } else {
                        fileListView()
                    }
                }
                .frame(minWidth: 380)

                // Right: detail panel
                if let selected = selectedEntry {
                    detailPanel(entry: selected)
                        .frame(width: 220)
                }
            }
        }
    }

    @ViewBuilder
    private func treemapView() -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Space Distribution")
                    .font(.headline).padding()
                Spacer()
                Text("\(manager.entries.count) items")
                    .font(.caption).foregroundStyle(.secondary).padding()
            }
            Divider()
            ScrollView {
                VStack(spacing: 6) {
                    let total = manager.entries.first?.sizeBytes ?? 1
                    ForEach(Array(manager.entries.prefix(40).enumerated()), id: \.element.id) { idx, entry in
                        treemapRow(entry: entry, total: total, index: idx)
                    }
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    private func treemapRow(entry: DiskEntry, total: Int64, index: Int) -> some View {
        let fraction = total > 0 ? Double(entry.sizeBytes) / Double(total) : 0
        let colors: [Color] = [.blue, .purple, .teal, .orange, .pink, .indigo, .cyan, .mint]
        let color = colors[index % colors.count]

        Button(action: {
            selectedEntry = entry
            if entry.isDirectory {
                pathInput = entry.path
                manager.scanDirectory(path: entry.path)
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: entry.isDirectory ? "folder.fill" : "doc.fill")
                    .foregroundStyle(entry.isDirectory ? color : .secondary)
                    .frame(width: 18)

                Text(entry.name)
                    .font(.subheadline)
                    .lineLimit(1)
                    .frame(maxWidth: 180, alignment: .leading)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color.opacity(0.1))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color.opacity(0.75))
                            .frame(width: max(2, geo.size.width * fraction))
                    }
                }
                .frame(height: 16)

                Text(String(format: "%.1f%%", fraction * 100))
                    .font(.caption2).foregroundStyle(.secondary)
                    .frame(width: 38, alignment: .trailing)

                Text(formatBytes(entry.sizeBytes))
                    .font(.caption).bold()
                    .frame(width: 70, alignment: .trailing)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(selectedEntry?.id == entry.id ? color.opacity(0.12) : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selectedEntry?.id == entry.id ? color.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func fileListView() -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Name").frame(maxWidth: .infinity, alignment: .leading)
                Text("Type").frame(width: 70)
                Text("Size").frame(width: 90, alignment: .trailing)
            }
            .font(.caption2).bold().foregroundStyle(.secondary)
            .padding(.horizontal).padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.2))

            Divider()

            List(selection: Binding(get: { selectedEntry?.id },
                                    set: { id in selectedEntry = manager.entries.first { $0.id == id } })) {
                ForEach(manager.entries) { entry in
                    HStack {
                        Image(systemName: entry.isDirectory ? "folder.fill" : "doc.fill")
                            .foregroundStyle(entry.isDirectory ? .blue : .secondary)
                            .frame(width: 18)
                        Text(entry.name).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                        Text(entry.isDirectory ? "Folder" : fileExtension(entry.name))
                            .font(.caption).foregroundStyle(.secondary).frame(width: 70)
                        Text(formatBytes(entry.sizeBytes))
                            .font(.caption).bold().frame(width: 90, alignment: .trailing)
                    }
                    .tag(entry.id)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        if entry.isDirectory {
                            pathInput = entry.path
                            manager.scanDirectory(path: entry.path)
                        }
                    }
                }
            }
            .listStyle(.inset)
        }
    }

    @ViewBuilder
    private func detailPanel(entry: DiskEntry) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: entry.isDirectory ? "folder.fill" : "doc.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(entry.isDirectory ? .blue : .secondary)
                Text(entry.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity)
            .padding(.top)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                detailRow("Size", formatBytes(entry.sizeBytes))
                detailRow("Type", entry.isDirectory ? "Folder" : fileExtension(entry.name))
                detailRow("Path", entry.path)
            }
            .padding(.horizontal)

            Divider()

            VStack(spacing: 8) {
                if entry.isDirectory {
                    Button("Open in Finder") {
                        NSWorkspace.shared.open(URL(fileURLWithPath: entry.path))
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)

                    Button("Explore Folder") {
                        pathInput = entry.path
                        manager.scanDirectory(path: entry.path)
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                } else {
                    Button("Reveal in Finder") {
                        NSWorkspace.shared.selectFile(entry.path, inFileViewerRootedAtPath: "")
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
    }

    @ViewBuilder
    private func detailRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.caption).lineLimit(3).truncationMode(.middle)
        }
    }

    @ViewBuilder
    private func scanningPlaceholder() -> some View {
        VStack(spacing: 16) {
            ProgressView(value: manager.scanProgress).frame(width: 240)
            Text("Scanning \(manager.currentPath.isEmpty ? "Home" : manager.currentPath)…")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func emptyStatePlaceholder() -> some View {
        VStack(spacing: 12) {
            Image(systemName: "internaldrive").font(.system(size: 40)).foregroundStyle(.secondary)
            Text("Nothing to show").font(.headline).foregroundStyle(.secondary)
            Text("Select a volume above or browse to a directory.").font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    private func fileExtension(_ name: String) -> String {
        let ext = (name as NSString).pathExtension
        return ext.isEmpty ? "File" : ext.uppercased()
    }

    private func volumeUsageColor(_ pct: Double) -> Color {
        pct > 0.9 ? .red : pct > 0.75 ? .orange : .accentColor
    }
}
