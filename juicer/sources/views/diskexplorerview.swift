import SwiftUI

struct diskexplorerview: View {
    @StateObject private var manager = DiskExplorerManager()
    @State private var pathInput: String = ""
    @State private var selectedEntry: DiskEntry?
    @State private var viewMode: ViewMode = .treemap

    enum ViewMode: String, CaseIterable {
        case treemap = "Bar Map"
        case list = "File List"
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection()
            Divider()
            volumeBar()
            Divider()

            if manager.isScanning {
                scanningPlaceholder()
            } else if manager.entries.isEmpty {
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
                Text("Visualize disk usage and find space hogs across your filesystem.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Picker("View", selection: $viewMode) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 180)

            Button(action: { manager.scanDirectory(path: manager.currentPath) }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .disabled(manager.isScanning)
            .help("Rescan current directory")
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }

    // MARK: - Volume Bar
    @ViewBuilder
    private func volumeBar() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(manager.volumes) { volume in
                    volumeCard(volume: volume)
                }

                // Path Navigation Bar
                HStack(spacing: 6) {
                    Image(systemName: "folder.fill").foregroundStyle(.secondary)
                    TextField("Custom path…", text: $pathInput)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                    Button("Go") {
                        let target = pathInput.isEmpty ? FileManager.default.homeDirectoryForCurrentUser.path : pathInput
                        manager.scanDirectory(path: target)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 8)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
    }

    @ViewBuilder
    private func volumeCard(volume: DiskVolume) -> some View {
        Button(action: { manager.scanDirectory(path: volume.mountPoint) }) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "internaldrive.fill")
                        .foregroundStyle(.blue)
                    Text(volume.name)
                        .font(.caption).bold()
                        .lineLimit(1)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.secondary.opacity(0.2))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(usageColor(pct: volume.usagePercent))
                            .frame(width: geo.size.width * volume.usagePercent)
                    }
                }
                .frame(width: 140, height: 6)

                HStack {
                    Text(manager.formatBytes(volume.usedBytes))
                        .font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    Text(manager.formatBytes(volume.totalBytes))
                        .font(.caption2).foregroundStyle(.secondary)
                }
                .frame(width: 140)
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(manager.currentPath == volume.mountPoint ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content Switcher
    @ViewBuilder
    private func contentView() -> some View {
        if viewMode == .treemap {
            barMapView()
        } else {
            fileListView()
        }
    }

    // MARK: - Bar Map View (Mole-inspired visual)
    @ViewBuilder
    private func barMapView() -> some View {
        HStack(spacing: 0) {
            // Left: Top 10 consumption bar
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Space Consumers")
                        .font(.headline).padding()
                    Spacer()
                    Text(manager.currentPath)
                        .font(.caption2).foregroundStyle(.tertiary)
                        .lineLimit(1).truncationMode(.middle)
                        .padding(.trailing)
                }
                Divider()

                ScrollView {
                    VStack(spacing: 8) {
                        let total = manager.entries.reduce(0) { $0 + $1.sizeBytes }
                        ForEach(Array(manager.topConsumers.enumerated()), id: \.element.id) { index, entry in
                            barConsumerRow(entry: entry, total: total, index: index)
                        }
                    }
                    .padding()
                }
            }
            .frame(maxWidth: .infinity)

            Divider()

            // Right: Selected entry detail
            if let entry = selectedEntry {
                entryDetailPanel(entry: entry)
                    .frame(width: 260)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "cursorarrow.click")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("Select an item to see details")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(width: 260)
            }
        }
    }

    @ViewBuilder
    private func barConsumerRow(entry: DiskEntry, total: Int64, index: Int) -> some View {
        let pct = total > 0 ? Double(entry.sizeBytes) / Double(total) : 0
        let colors: [Color] = [.blue, .purple, .orange, .pink, .teal, .indigo, .cyan, .green, .red, .yellow]
        let color = colors[index % colors.count]

        Button(action: { selectedEntry = entry }) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: entry.isDirectory ? "folder.fill" : "doc.fill")
                        .foregroundStyle(color)
                    Text(entry.name)
                        .font(.subheadline).bold()
                        .lineLimit(1)
                    Spacer()
                    Text(manager.formatBytes(entry.sizeBytes))
                        .font(.subheadline).bold()
                        .foregroundStyle(.primary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.1))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color.opacity(0.7))
                            .frame(width: geo.size.width * pct)
                    }
                }
                .frame(height: 8)
                Text(String(format: "%.1f%% of folder", pct * 100))
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .padding(10)
            .background(selectedEntry?.id == entry.id ? color.opacity(0.08) : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selectedEntry?.id == entry.id ? color.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - File List View
    @ViewBuilder
    private func fileListView() -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Name")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Size")
                    .frame(width: 120, alignment: .trailing)
                Text("Actions")
                    .frame(width: 100, alignment: .center)
            }
            .font(.caption).bold()
            .foregroundStyle(.secondary)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.3))

            Divider()

            List(manager.entries.sorted { $0.sizeBytes > $1.sizeBytes }) { entry in
                HStack {
                    Image(systemName: entry.isDirectory ? "folder.fill" : "doc.fill")
                        .foregroundStyle(entry.isDirectory ? .blue : .secondary)
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.name).font(.body).lineLimit(1)
                        Text(entry.path).font(.caption2).foregroundStyle(.tertiary)
                            .lineLimit(1).truncationMode(.middle)
                    }
                    Spacer()
                    Text(manager.formatBytes(entry.sizeBytes))
                        .font(.subheadline).bold()
                        .frame(width: 100, alignment: .trailing)

                    HStack(spacing: 4) {
                        if entry.isDirectory {
                            Button(action: {
                                manager.scanDirectory(path: entry.path)
                                pathInput = entry.path
                            }) {
                                Image(systemName: "arrow.forward.circle")
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.blue)
                            .help("Explore this folder")
                        }
                        Button(action: { manager.revealInFinder(path: entry.path) }) {
                            Image(systemName: "arrow.up.forward.square")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .help("Reveal in Finder")
                    }
                    .frame(width: 60, alignment: .center)
                }
                .padding(.vertical, 4)
            }
            .listStyle(.inset)
        }
    }

    // MARK: - Detail Panel
    @ViewBuilder
    private func entryDetailPanel(entry: DiskEntry) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 56, height: 56)
                    Image(systemName: entry.isDirectory ? "folder.fill" : "doc.fill")
                        .font(.title)
                        .foregroundStyle(.blue)
                }
                Text(entry.name)
                    .font(.headline)
                Text(entry.isDirectory ? "Folder" : "File")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                detailRow(label: "Size", value: manager.formatBytes(entry.sizeBytes))
                detailRow(label: "Path", value: entry.path)
            }

            Spacer()

            VStack(spacing: 8) {
                Button(action: { manager.revealInFinder(path: entry.path) }) {
                    HStack {
                        Image(systemName: "arrow.up.forward.square")
                        Text("Reveal in Finder")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                if entry.isDirectory {
                    Button(action: {
                        manager.scanDirectory(path: entry.path)
                        pathInput = entry.path
                        selectedEntry = nil
                    }) {
                        HStack {
                            Image(systemName: "arrow.forward.circle")
                            Text("Explore Folder")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
    }

    @ViewBuilder
    private func detailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary).bold()
            Text(value).font(.caption2).foregroundStyle(.primary)
                .lineLimit(4).fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Scanning
    @ViewBuilder
    private func scanningPlaceholder() -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.2)
            Text("Scanning disk usage…")
                .font(.headline).foregroundStyle(.secondary)
            Text(manager.currentPath)
                .font(.caption2).foregroundStyle(.tertiary)
                .lineLimit(1).truncationMode(.middle)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func emptyStatePlaceholder() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "internaldrive")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No items found")
                .font(.headline).foregroundStyle(.secondary)
            Text("The selected directory appears to be empty or inaccessible.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers
    private func usageColor(pct: Double) -> Color {
        if pct < 0.5 { return .green }
        else if pct < 0.8 { return .orange }
        else { return .red }
    }
}
