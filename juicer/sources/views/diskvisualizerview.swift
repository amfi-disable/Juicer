import SwiftUI
import AppKit
import QuickLook

// MARK: - View Mode

enum DiskViewMode: String, CaseIterable {
    case treemap = "Treemap"
    case sunburst = "Sunburst"

    var icon: String {
        switch self {
        case .treemap:  return "square.split.2x2"
        case .sunburst: return "chart.pie.fill"
        }
    }
}

// MARK: - Sort Mode

enum DiskSortMode: String, CaseIterable {
    case sizeDesc  = "Largest First"
    case sizeAsc   = "Smallest First"
    case nameAsc   = "Name A–Z"
    case nameDesc  = "Name Z–A"
}

// MARK: - Treemap Item

struct TreemapItem: Identifiable {
    let id        = UUID()
    let name      : String
    let path      : String
    let sizeBytes : Int64
    let isDirectory: Bool
    let rect      : CGRect
    let depth     : Int
    let color     : Color
    let ratio     : Double   // fraction of parent total
}

// MARK: - Sunburst Arc

struct SunburstArc: Identifiable {
    let id        = UUID()
    let name      : String
    let path      : String
    let sizeBytes : Int64
    let isDirectory: Bool
    let depth     : Int
    let startAngle: Double   // radians
    let endAngle  : Double   // radians
    let innerR    : CGFloat
    let outerR    : CGFloat
    let color     : Color
    let ratio     : Double
}

// MARK: - Discard Pile

class DiscardPile: ObservableObject {
    @Published var items: [DiskEntry] = []

    func add(_ entry: DiskEntry) {
        guard !items.contains(where: { $0.path == entry.path }) else { return }
        items.append(entry)
    }

    func remove(_ entry: DiskEntry) {
        items.removeAll { $0.path == entry.path }
    }

    func trashAll() {
        for item in items {
            try? FileManager.default.trashItem(at: URL(fileURLWithPath: item.path), resultingItemURL: nil)
        }
        items = []
    }
}

// MARK: - Main View

struct diskvisualizerview: View {

    // MARK: State
    @StateObject private var manager     = DiskExplorerManager()
    @StateObject private var discardPile = DiscardPile()

    @State private var pathInput         : String    = ""
    @State private var viewMode          : DiskViewMode = .treemap
    @State private var sortMode          : DiskSortMode = .sizeDesc
    @State private var depthLimit        : Int       = 3
    @State private var selectedItem      : DiskEntry?
    @State private var hoveredPath       : String?   = nil
    @State private var tooltipPos        : CGPoint   = .zero
    @State private var breadcrumbs       : [String]  = []
    @State private var navHistory        : [String]  = []
    @State private var navFuture         : [String]  = []
    @State private var showDiscardPile   : Bool      = false
    @State private var showConfirmTrash  : Bool      = false
    @State private var qlItem            : URL?      = nil

    // MARK: Computed helpers

    private var sortedEntries: [DiskEntry] {
        switch sortMode {
        case .sizeDesc:  return manager.entries.sorted { $0.sizeBytes > $1.sizeBytes }
        case .sizeAsc:   return manager.entries.sorted { $0.sizeBytes < $1.sizeBytes }
        case .nameAsc:   return manager.entries.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDesc:  return manager.entries.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        }
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            headerSection()
            Divider()
            breadcrumbBar()
            Divider()

            HSplitView {
                // LEFT — chart area
                VStack(spacing: 0) {
                    chartArea()
                    Divider()
                    legendBar()
                }
                .frame(minWidth: 400)

                // RIGHT — inspector panel
                inspectorPanel()
                    .frame(minWidth: 240, maxWidth: 320)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            navigate(to: home, addHistory: false)
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            _ = providers.first?.loadObject(ofClass: URL.self) { url, _ in
                if let url, url.hasDirectoryPath {
                    DispatchQueue.main.async { navigate(to: url.path) }
                }
            }
            return true
        }
        .sheet(isPresented: $showDiscardPile) {
            discardPileSheet()
        }
        .alert("Move to Trash?", isPresented: $showConfirmTrash) {
            Button("Cancel", role: .cancel) {}
            Button("Move to Trash", role: .destructive) {
                if let item = selectedItem {
                    try? FileManager.default.trashItem(
                        at: URL(fileURLWithPath: item.path),
                        resultingItemURL: nil
                    )
                    selectedItem = nil
                    manager.scanDirectory(path: manager.currentPath)
                }
            }
        } message: {
            if let item = selectedItem {
                Text("Move '\(item.name)' to the Trash?\n\(formatBytes(item.sizeBytes))")
            }
        }
        .quickLookPreview($qlItem)
    }

    // MARK: - Header

    @ViewBuilder
    private func headerSection() -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Disk Visualizer")
                    .font(.title2).bold()
                Text("Explore disk usage with treemap & sunburst views. Double-click folders to drill in.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            // View toggle
            Picker("", selection: $viewMode) {
                ForEach(DiskViewMode.allCases, id: \.self) { mode in
                    Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)

            // Sort
            Menu {
                ForEach(DiskSortMode.allCases, id: \.self) { mode in
                    Button(mode.rawValue) { sortMode = mode }
                }
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
            }
            .menuStyle(.borderlessButton)
            .frame(width: 80)

            // Depth
            HStack(spacing: 4) {
                Text("Depth").font(.caption).foregroundStyle(.secondary)
                Stepper("\(depthLimit)", value: $depthLimit, in: 1...6)
                    .frame(width: 100)
            }

            // Discard pile badge
            Button {
                showDiscardPile = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "checklist")
                    if !discardPile.items.isEmpty {
                        Text("\(discardPile.items.count)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(3)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 6, y: -6)
                    }
                }
            }
            .buttonStyle(.bordered)
            .help("Discard Pile")

            Button(action: { manager.scanDirectory(path: manager.currentPath) }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .disabled(manager.isScanning)
        }
        .padding(.horizontal).padding(.vertical, 10)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
    }

    // MARK: - Breadcrumb Bar

    @ViewBuilder
    private func breadcrumbBar() -> some View {
        HStack(spacing: 6) {
            // Back
            Button(action: navBack) {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.bordered)
            .disabled(navHistory.isEmpty || manager.isScanning)

            // Forward
            Button(action: navForward) {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.bordered)
            .disabled(navFuture.isEmpty || manager.isScanning)

            // Home
            Button {
                navigate(to: FileManager.default.homeDirectoryForCurrentUser.path)
            } label: {
                Image(systemName: "house.fill")
            }
            .buttonStyle(.bordered)

            // Crumbs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(Array(breadcrumbs.enumerated()), id: \.offset) { idx, crumb in
                        if idx > 0 {
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        let crumbPath = breadcrumbs[0...idx].joined(separator: "/").replacingOccurrences(of: "//", with: "/")
                        Button(crumb.isEmpty ? "/" : crumb) {
                            navigate(to: crumbPath.isEmpty ? "/" : crumbPath)
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(idx == breadcrumbs.count - 1 ? .primary : .secondary)
                    }
                }
                .padding(.horizontal, 4)
            }

            Spacer()

            // Path text field
            TextField("Path…", text: $pathInput, onCommit: { navigate(to: pathInput) })
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 280)

            Button("Browse…") { pickFolder() }
                .buttonStyle(.bordered)
        }
        .padding(.horizontal).padding(.vertical, 5)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.2))
    }

    // MARK: - Chart Area

    @ViewBuilder
    private func chartArea() -> some View {
        GeometryReader { geo in
            ZStack {
                if manager.isScanning {
                    VStack(spacing: 14) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(1.4)
                        Text(String(format: "Scanning… %.0f%%", manager.scanProgress * 100))
                            .font(.subheadline).foregroundStyle(.secondary)
                        Text(manager.currentPath)
                            .font(.caption2).foregroundStyle(.tertiary)
                            .lineLimit(1).truncationMode(.middle)
                            .frame(maxWidth: 320)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if manager.entries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "externaldrive.badge.questionmark")
                            .font(.system(size: 52))
                            .foregroundStyle(.quaternary)
                        Text("No data to visualize")
                            .font(.title3).bold().foregroundStyle(.secondary)
                        Text("Browse or drop a folder here to begin.")
                            .font(.subheadline).foregroundStyle(.tertiary)
                        Button("Scan Home Folder") {
                            navigate(to: FileManager.default.homeDirectoryForCurrentUser.path)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else {
                    switch viewMode {
                    case .treemap:
                        treemapCanvas(size: geo.size)
                    case .sunburst:
                        sunburstCanvas(size: geo.size)
                    }

                    // Floating tooltip
                    if let path = hoveredPath,
                       let entry = sortedEntries.first(where: { $0.path == path }) {
                        tooltipView(entry: entry)
                            .position(tooltipPos)
                            .allowsHitTesting(false)
                            .animation(.easeOut(duration: 0.08), value: tooltipPos)
                    }
                }
            }
        }
        .background(Color(NSColor.underPageBackgroundColor).opacity(0.25))
    }

    // MARK: - Treemap Canvas

    @ViewBuilder
    private func treemapCanvas(size: CGSize) -> some View {
        let entries = sortedEntries
        let rect    = CGRect(origin: .zero, size: size).insetBy(dx: 2, dy: 2)
        let items   = squarifiedLayout(entries: entries, in: rect, depth: 0, maxDepth: depthLimit)

        ZStack(alignment: .topLeading) {
            ForEach(items) { item in
                treemapCell(item: item)
            }
        }
        .frame(width: size.width, height: size.height)
    }

    @ViewBuilder
    private func treemapCell(item: TreemapItem) -> some View {
        let isSelected = selectedItem?.path == item.path
        let isHovered  = hoveredPath == item.path

        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(item.color.opacity(isHovered ? 1.0 : 0.85))

            RoundedRectangle(cornerRadius: 3)
                .stroke(
                    isSelected ? Color.white : (isHovered ? Color.white.opacity(0.7) : Color.black.opacity(0.12)),
                    lineWidth: isSelected ? 2.5 : 0.8
                )

            if item.rect.width > 50 && item.rect.height > 28 {
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.name)
                        .font(.system(size: min(11, item.rect.width / 8), weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(formatBytes(item.sizeBytes))
                        .font(.system(size: min(9, item.rect.width / 10), weight: .regular))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                    if item.rect.height > 44 {
                        Text(String(format: "%.1f%%", item.ratio * 100))
                            .font(.system(size: min(8, item.rect.width / 12)))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding(4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .frame(width: max(item.rect.width, 1), height: max(item.rect.height, 1))
        .offset(x: item.rect.origin.x, y: item.rect.origin.y)
        .onHover { inside in
            hoveredPath = inside ? item.path : nil
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { val in tooltipPos = clampTooltip(val.location, in: CGSize(width: item.rect.width + item.rect.origin.x, height: item.rect.height + item.rect.origin.y)) }
        )
        .onTapGesture(count: 2) {
            if item.isDirectory { navigate(to: item.path) }
        }
        .onTapGesture(count: 1) {
            selectedItem = manager.entries.first { $0.path == item.path }
        }
        .scaleEffect(isHovered ? 1.005 : 1.0)
        .animation(.interactiveSpring(response: 0.12, dampingFraction: 0.9), value: isHovered)
    }

    // MARK: - Sunburst Canvas

    @ViewBuilder
    private func sunburstCanvas(size: CGSize) -> some View {
        let arcs = buildSunburstArcs(entries: sortedEntries, size: size, maxDepth: depthLimit)
        let cx   = size.width  / 2
        let cy   = size.height / 2
        let centerEntry = hoveredPath.flatMap { p in sortedEntries.first { $0.path == p } }

        ZStack {
            Canvas { ctx, _ in
                for arc in arcs {
                    let path = sunburstPath(arc: arc, cx: cx, cy: cy)
                    ctx.fill(path, with: .color(arc.color.opacity(0.88)))
                    ctx.stroke(path, with: .color(.white.opacity(0.15)), lineWidth: 0.8)
                }
            }
            .contentShape(Rectangle())

            // Invisible hit-test overlays per arc
            ForEach(arcs) { arc in
                sunburstHitArea(arc: arc, cx: cx, cy: cy, size: size)
            }

            // Center label
            VStack(spacing: 4) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.secondary)
                Text(centerEntry?.name ?? (manager.currentPath as NSString).lastPathComponent)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 90)
                if let entry = centerEntry {
                    Text(formatBytes(entry.sizeBytes))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 110)
            .position(x: cx, y: cy)
            .allowsHitTesting(false)

            // Floating tooltip
            if let path = hoveredPath,
               let entry = sortedEntries.first(where: { $0.path == path }) {
                tooltipView(entry: entry)
                    .position(tooltipPos)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: size.width, height: size.height)
    }

    @ViewBuilder
    private func sunburstHitArea(arc: SunburstArc, cx: CGFloat, cy: CGFloat, size: CGSize) -> some View {
        let isHovered  = hoveredPath == arc.path
        let isSelected = selectedItem?.path == arc.path

        // We draw a tiny invisible rect over the center of each arc for hit testing
        let midAngle  = (arc.startAngle + arc.endAngle) / 2
        let midRadius = (arc.innerR + arc.outerR) / 2
        let x = cx + midRadius * CGFloat(cos(midAngle))
        let y = cy + midRadius * CGFloat(sin(midAngle))

        Circle()
            .fill(Color.clear)
            .frame(width: 1, height: 1)
            .position(x: x, y: y)
            .contentShape(sunburstHitShape(arc: arc, cx: cx, cy: cy))
            .onHover { inside in
                hoveredPath = inside ? arc.path : nil
                if inside {
                    tooltipPos = CGPoint(x: x + 20, y: y)
                    tooltipPos = clampTooltip(tooltipPos, in: size)
                }
            }
            .onTapGesture(count: 2) {
                if arc.isDirectory { navigate(to: arc.path) }
            }
            .onTapGesture(count: 1) {
                selectedItem = manager.entries.first { $0.path == arc.path }
            }
            .overlay(
                isSelected ? AnyView(
                    sunburstSelectedRing(arc: arc, cx: cx, cy: cy)
                ) : AnyView(EmptyView())
            )
    }

    private func sunburstHitShape(arc: SunburstArc, cx: CGFloat, cy: CGFloat) -> some Shape {
        return AnnularSector(
            startAngle: arc.startAngle,
            endAngle: arc.endAngle,
            innerRadius: arc.innerR,
            outerRadius: arc.outerR,
            cx: cx, cy: cy
        )
    }

    @ViewBuilder
    private func sunburstSelectedRing(arc: SunburstArc, cx: CGFloat, cy: CGFloat) -> some View {
        Canvas { ctx, size in
            let path = sunburstPath(arc: arc, cx: cx, cy: cy)
            ctx.stroke(path, with: .color(.white), lineWidth: 2.5)
        }
        .allowsHitTesting(false)
    }

    private func sunburstPath(arc: SunburstArc, cx: CGFloat, cy: CGFloat) -> Path {
        var path = Path()
        let startDeg = Angle(radians: arc.startAngle)
        let endDeg   = Angle(radians: arc.endAngle)
        path.addArc(center: CGPoint(x: cx, y: cy), radius: arc.outerR,
                    startAngle: startDeg, endAngle: endDeg, clockwise: false)
        path.addArc(center: CGPoint(x: cx, y: cy), radius: arc.innerR,
                    startAngle: endDeg, endAngle: startDeg, clockwise: true)
        path.closeSubpath()
        return path
    }

    // MARK: - Tooltip

    @ViewBuilder
    private func tooltipView(entry: DiskEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: entry.isDirectory ? "folder.fill" : fileIcon(for: entry.name))
                    .foregroundStyle(fileColor(for: entry))
                Text(entry.name)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(2)
            }
            Text(formatBytes(entry.sizeBytes))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
            Text((entry.path as NSString).abbreviatingWithTildeInPath)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 3)
        )
        .frame(maxWidth: 220)
    }

    private func clampTooltip(_ pos: CGPoint, in size: CGSize) -> CGPoint {
        let w: CGFloat = 230
        let h: CGFloat = 72
        let x = min(max(pos.x + 16, w / 2 + 8), size.width  - w / 2 - 8)
        let y = min(max(pos.y - 20, h / 2 + 8), size.height - h / 2 - 8)
        return CGPoint(x: x, y: y)
    }

    // MARK: - Legend Bar

    @ViewBuilder
    private func legendBar() -> some View {
        let legend: [(color: Color, label: String)] = [
            (.blue.opacity(0.75),   "Folder"),
            (.pink.opacity(0.85),   "Media"),
            (.teal.opacity(0.85),   "Code"),
            (.orange.opacity(0.85), "Archive"),
            (.purple.opacity(0.85), "Image"),
            (.mint.opacity(0.85),   "Document"),
            (.gray.opacity(0.7),    "Other"),
        ]
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(legend, id: \.label) { item in
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(item.color)
                            .frame(width: 12, height: 12)
                        Text(item.label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
        }
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }

    // MARK: - Inspector Panel

    @ViewBuilder
    private func inspectorPanel() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let item = selectedItem {
                    inspectorHeader(item)
                    Divider().padding(.vertical, 4)
                    inspectorMetadata(item)
                    Divider().padding(.vertical, 4)
                    inspectorActions(item)
                } else {
                    topConsumersPanel()
                }
            }
            .padding()
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
    }

    @ViewBuilder
    private func inspectorHeader(_ item: DiskEntry) -> some View {
        HStack(spacing: 10) {
            Image(systemName: item.isDirectory ? "folder.fill" : fileIcon(for: item.name))
                .font(.system(size: 28))
                .foregroundStyle(fileColor(for: item))
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(2)
                Text(item.isDirectory ? "Folder" : fileKindLabel(for: item.name))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                selectedItem = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func inspectorMetadata(_ item: DiskEntry) -> some View {
        let total = manager.entries.reduce(0) { $0 + $1.sizeBytes }
        let pct   = total > 0 ? Double(item.sizeBytes) / Double(total) * 100 : 0

        VStack(spacing: 8) {
            // Size bar
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("Size").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text(formatBytes(item.sizeBytes)).font(.caption.monospacedDigit()).bold()
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.15))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(fileColor(for: item))
                            .frame(width: geo.size.width * CGFloat(pct / 100))
                    }
                }
                .frame(height: 6)
                Text(String(format: "%.1f%% of this folder", pct))
                    .font(.caption2).foregroundStyle(.tertiary)
            }

            Divider()

            // Path
            VStack(alignment: .leading, spacing: 3) {
                Text("Path").font(.caption).foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Text((item.path as NSString).abbreviatingWithTildeInPath)
                        .font(.system(size: 10))
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                        .truncationMode(.middle)
                    Spacer()
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(item.path, forType: .string)
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.plain)
                    .help("Copy path")
                }
            }
        }
    }

    @ViewBuilder
    private func inspectorActions(_ item: DiskEntry) -> some View {
        VStack(spacing: 8) {
            Text("Actions").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)

            // Quick Look (files only)
            if !item.isDirectory {
                Button {
                    qlItem = URL(fileURLWithPath: item.path)
                } label: {
                    Label("Quick Look", systemImage: "eye")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            // Open
            Button {
                NSWorkspace.shared.open(URL(fileURLWithPath: item.path))
            } label: {
                Label("Open", systemImage: "arrow.up.forward.app")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            // Reveal in Finder
            Button {
                NSWorkspace.shared.selectFile(item.path, inFileViewerRootedAtPath: "")
            } label: {
                Label("Reveal in Finder", systemImage: "arrow.up.forward.square")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            // Add to Discard Pile
            let inPile = discardPile.items.contains { $0.path == item.path }
            Button {
                if inPile { discardPile.remove(item) } else { discardPile.add(item) }
            } label: {
                Label(inPile ? "Remove from Discard Pile" : "Add to Discard Pile",
                      systemImage: inPile ? "minus.circle" : "checklist.checked")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(inPile ? .orange : .primary)

            // Drill in (directories)
            if item.isDirectory {
                Button {
                    navigate(to: item.path)
                } label: {
                    Label("Open in Visualizer", systemImage: "plus.magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
            }

            // Trash
            Button(role: .destructive) {
                showConfirmTrash = true
            } label: {
                Label("Move to Trash", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Top Consumers Panel

    @ViewBuilder
    private func topConsumersPanel() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.orange)
                Text("Top Consumers")
                    .font(.headline)
            }

            if manager.topConsumers.isEmpty {
                Text("Scan a folder to see the largest items.")
                    .font(.caption).foregroundStyle(.tertiary)
            } else {
                let total = manager.entries.reduce(0) { $0 + $1.sizeBytes }
                ForEach(Array(manager.topConsumers.prefix(12)), id: \.path) { entry in
                    Button {
                        selectedItem = entry
                    } label: {
                        topConsumerRow(entry: entry, total: total)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            if !discardPile.items.isEmpty {
                Divider()
                HStack {
                    Image(systemName: "checklist").foregroundStyle(.orange)
                    Text("Discard Pile (\(discardPile.items.count) items)")
                        .font(.subheadline).bold()
                    Spacer()
                    Button("Review") { showDiscardPile = true }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                }
            }
        }
    }

    @ViewBuilder
    private func topConsumerRow(entry: DiskEntry, total: Int64) -> some View {
        let pct = total > 0 ? Double(entry.sizeBytes) / Double(total) : 0

        HStack(spacing: 8) {
            Image(systemName: entry.isDirectory ? "folder.fill" : fileIcon(for: entry.name))
                .foregroundStyle(fileColor(for: entry))
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.12))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(fileColor(for: entry).opacity(0.75))
                            .frame(width: geo.size.width * CGFloat(pct))
                    }
                }
                .frame(height: 4)
            }
            Text(formatBytes(entry.sizeBytes))
                .font(.system(size: 10).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 56, alignment: .trailing)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Discard Pile Sheet

    @ViewBuilder
    private func discardPileSheet() -> some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "checklist").foregroundStyle(.orange)
                Text("Discard Pile").font(.title2).bold()
                Spacer()
                Button("Done") { showDiscardPile = false }
                    .buttonStyle(.bordered)
            }
            .padding()

            Divider()

            if discardPile.items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray").font(.system(size: 40)).foregroundStyle(.tertiary)
                    Text("Nothing staged for deletion.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(discardPile.items, id: \.path) { item in
                        HStack {
                            Image(systemName: item.isDirectory ? "folder.fill" : fileIcon(for: item.name))
                                .foregroundStyle(fileColor(for: item))
                            VStack(alignment: .leading) {
                                Text(item.name).font(.subheadline)
                                Text(item.path).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                            }
                            Spacer()
                            Text(formatBytes(item.sizeBytes)).font(.caption.monospacedDigit())
                            Button {
                                discardPile.remove(item)
                            } label: {
                                Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .listStyle(.plain)

                Divider()

                let totalBytes = discardPile.items.reduce(0) { $0 + $1.sizeBytes }
                HStack {
                    Text("\(discardPile.items.count) items — \(formatBytes(totalBytes)) total")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                    Button("Clear All") { discardPile.items = [] }
                        .buttonStyle(.bordered)
                    Button("Move All to Trash", role: .destructive) {
                        discardPile.trashAll()
                        manager.scanDirectory(path: manager.currentPath)
                        showDiscardPile = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding()
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }

    // MARK: - Navigation

    private func navigate(to path: String, addHistory: Bool = true) {
        let clean = path.hasSuffix("/") && path.count > 1 ? String(path.dropLast()) : path
        if addHistory && !manager.currentPath.isEmpty && manager.currentPath != clean {
            navHistory.append(manager.currentPath)
            navFuture = []
        }
        pathInput  = clean
        breadcrumbs = makeBreadcrumbs(from: clean)
        manager.scanDirectory(path: clean)
        selectedItem = nil
        hoveredPath  = nil
    }

    private func navBack() {
        guard let prev = navHistory.popLast() else { return }
        navFuture.insert(manager.currentPath, at: 0)
        pathInput    = prev
        breadcrumbs  = makeBreadcrumbs(from: prev)
        manager.scanDirectory(path: prev)
        selectedItem = nil
    }

    private func navForward() {
        guard let next = navFuture.first else { return }
        navFuture.removeFirst()
        navHistory.append(manager.currentPath)
        pathInput    = next
        breadcrumbs  = makeBreadcrumbs(from: next)
        manager.scanDirectory(path: next)
        selectedItem = nil
    }

    private func makeBreadcrumbs(from path: String) -> [String] {
        let parts = path.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        return parts.isEmpty ? ["/"] : parts
    }

    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles       = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: manager.currentPath.isEmpty ?
            FileManager.default.homeDirectoryForCurrentUser.path : manager.currentPath)
        if panel.runModal() == .OK, let url = panel.url {
            navigate(to: url.path)
        }
    }

    // MARK: - Squarified Treemap Layout

    private func squarifiedLayout(entries: [DiskEntry], in rect: CGRect, depth: Int, maxDepth: Int) -> [TreemapItem] {
        guard !entries.isEmpty, rect.width > 2, rect.height > 2 else { return [] }

        let totalSize = entries.reduce(0) { $0 + $1.sizeBytes }
        guard totalSize > 0 else { return [] }

        // Squarified: lay out rows that minimise the worst aspect ratio
        var items: [TreemapItem] = []
        var remaining = entries.sorted { $0.sizeBytes > $1.sizeBytes }
        var availRect = rect

        while !remaining.isEmpty {
            let rowItems = bestRow(from: remaining, in: availRect, total: totalSize)
            let rowCount  = rowItems.count
            let rowSize   = rowItems.reduce(0) { $0 + $1.sizeBytes }
            let rowRatio  = CGFloat(rowSize) / CGFloat(totalSize)

            let horizontal = availRect.width >= availRect.height
            let rowThickness: CGFloat = horizontal
                ? availRect.height * rowRatio
                : availRect.width  * rowRatio

            var cursor: CGFloat = horizontal ? availRect.minX : availRect.minY
            for entry in rowItems {
                let entryRatio  = Double(entry.sizeBytes) / Double(max(rowSize, 1))
                let entryLength = (horizontal ? availRect.width : availRect.height) * rowRatio * CGFloat(entryRatio / rowRatio)
                let cellRect: CGRect
                if horizontal {
                    let w = (availRect.height > 0 && rowThickness > 0)
                        ? CGFloat(entry.sizeBytes) / CGFloat(max(rowSize, 1)) * availRect.width
                        : 0
                    cellRect = CGRect(x: cursor, y: availRect.minY, width: w, height: rowThickness)
                    cursor += w
                } else {
                    let h = CGFloat(entry.sizeBytes) / CGFloat(max(rowSize, 1)) * availRect.height
                    cellRect = CGRect(x: availRect.minX, y: cursor, width: rowThickness, height: h)
                    cursor += h
                }

                let color = fileColor(for: entry, depth: depth)
                let item  = TreemapItem(
                    name: entry.name, path: entry.path, sizeBytes: entry.sizeBytes,
                    isDirectory: entry.isDirectory,
                    rect: cellRect.insetBy(dx: 1, dy: 1),
                    depth: depth,
                    color: color,
                    ratio: Double(entry.sizeBytes) / Double(max(totalSize, 1))
                )
                items.append(item)
            }

            remaining.removeFirst(rowCount)
            if horizontal {
                availRect = CGRect(x: availRect.minX, y: availRect.minY + rowThickness,
                                   width: availRect.width, height: availRect.height - rowThickness)
            } else {
                availRect = CGRect(x: availRect.minX + rowThickness, y: availRect.minY,
                                   width: availRect.width - rowThickness, height: availRect.height)
            }
        }
        return items
    }

    private func bestRow(from entries: [DiskEntry], in rect: CGRect, total: Int64) -> [DiskEntry] {
        // Greedy squarify: add items until aspect ratio stops improving
        let side = min(rect.width, rect.height)
        guard side > 0, total > 0 else { return Array(entries.prefix(1)) }

        var best: [DiskEntry] = []
        var bestWorst: CGFloat = .infinity

        var current: [DiskEntry] = []
        var currentSum: Int64    = 0

        for entry in entries {
            current.append(entry)
            currentSum += entry.sizeBytes
            let rowArea = CGFloat(currentSum) / CGFloat(total) * rect.width * rect.height
            let thickness = side > 0 ? rowArea / side : 0
            var worst: CGFloat = 0
            for e in current {
                let eArea = CGFloat(e.sizeBytes) / CGFloat(max(currentSum, 1)) * rowArea
                let len   = thickness > 0 ? eArea / thickness : 0
                let ar    = max(thickness, len) / max(min(thickness, len), 0.001)
                worst = max(worst, ar)
            }
            if worst < bestWorst {
                bestWorst = worst
                best = current
            } else {
                break
            }
        }
        return best.isEmpty ? Array(entries.prefix(1)) : best
    }

    // MARK: - Sunburst Layout

    private func buildSunburstArcs(entries: [DiskEntry], size: CGSize, maxDepth: Int) -> [SunburstArc] {
        let totalSize = entries.reduce(0) { $0 + $1.sizeBytes }
        guard totalSize > 0 else { return [] }

        let minDim    = min(size.width, size.height)
        let ringWidth : CGFloat = (minDim / 2 - 54) / CGFloat(min(maxDepth, 4))
        let innerStart: CGFloat = 54  // center hole radius

        var arcs: [SunburstArc] = []
        let startAngle = -Double.pi / 2  // 12 o'clock

        var angle = startAngle
        for entry in entries.sorted(by: { $0.sizeBytes > $1.sizeBytes }) {
            let fraction  = Double(entry.sizeBytes) / Double(totalSize)
            let span      = fraction * 2 * Double.pi
            let innerR    = innerStart
            let outerR    = innerStart + ringWidth

            arcs.append(SunburstArc(
                name: entry.name, path: entry.path, sizeBytes: entry.sizeBytes,
                isDirectory: entry.isDirectory,
                depth: 0,
                startAngle: angle, endAngle: angle + span,
                innerR: innerR, outerR: outerR,
                color: fileColor(for: entry, depth: 0),
                ratio: fraction
            ))

            // Add children (one level deeper)
            if entry.isDirectory && maxDepth > 1, !entry.children.isEmpty {
                var childAngle = angle
                for child in entry.children.sorted(by: { $0.sizeBytes > $1.sizeBytes }) {
                    let cf = Double(child.sizeBytes) / Double(max(entry.sizeBytes, 1))
                    let cs = cf * span
                    arcs.append(SunburstArc(
                        name: child.name, path: child.path, sizeBytes: child.sizeBytes,
                        isDirectory: child.isDirectory,
                        depth: 1,
                        startAngle: childAngle, endAngle: childAngle + cs,
                        innerR: outerR + 2, outerR: outerR + ringWidth,
                        color: fileColor(for: child, depth: 1),
                        ratio: cf * fraction
                    ))
                    childAngle += cs
                }
            }

            angle += span
        }
        return arcs
    }

    // MARK: - Color / Icon Helpers

    private func fileColor(for entry: DiskEntry, depth: Int = 0) -> Color {
        let base = fileColorBase(for: entry)
        // Darken slightly by depth
        let factor = 1.0 - Double(depth) * 0.10
        return base.opacity(max(0.5, factor))
    }

    private func fileColorBase(for entry: DiskEntry) -> Color {
        if entry.isDirectory { return .blue }
        let ext = (entry.name as NSString).pathExtension.lowercased()
        switch ext {
        case "mp4","mkv","avi","mov","mp3","wav","flac","aac","m4a","ogg","wma":
            return .pink
        case "swift","go","py","kt","rs","js","ts","html","css","cpp","c","h","java","rb","php","json","yml","yaml","xml","sh","bash","zsh":
            return .teal
        case "zip","tar","gz","bz2","rar","7z","dmg","pkg","xip","deb","rpm","iso":
            return .orange
        case "png","jpg","jpeg","gif","svg","heic","webp","tiff","bmp","raw","cr2","arw":
            return .purple
        case "pdf","doc","docx","xls","xlsx","ppt","pptx","pages","numbers","keynote","txt","rtf","md","csv":
            return .mint
        default:
            return .gray
        }
    }

    private func fileIcon(for name: String) -> String {
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "mp4","mkv","avi","mov":      return "film.fill"
        case "mp3","wav","flac","aac","m4a","ogg": return "music.note"
        case "png","jpg","jpeg","gif","heic","webp","tiff": return "photo.fill"
        case "pdf":                        return "doc.richtext.fill"
        case "zip","tar","gz","dmg","pkg","rar","7z": return "archivebox.fill"
        case "swift","py","js","ts","rs","go","kt","java","rb","cpp","c","h": return "chevron.left.forwardslash.chevron.right"
        case "doc","docx","txt","md","rtf","pages": return "doc.text.fill"
        case "xls","xlsx","numbers","csv": return "tablecells.fill"
        case "ppt","pptx","keynote":       return "slider.horizontal.below.rectangle"
        default:                           return "doc.fill"
        }
    }

    private func fileKindLabel(for name: String) -> String {
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "mp4","mkv","avi","mov":      return "Video File"
        case "mp3","wav","flac","aac","m4a": return "Audio File"
        case "png","jpg","jpeg","gif","heic","webp": return "Image File"
        case "pdf":                        return "PDF Document"
        case "zip","tar","gz","dmg","pkg","rar","7z": return "Archive"
        case "swift","py","js","ts","rs","go","kt","java": return "Source Code"
        case "doc","docx","txt","md","rtf","pages": return "Document"
        case "xls","xlsx","numbers","csv": return "Spreadsheet"
        default:                           return "\(ext.uppercased()) File"
        }
    }

    // MARK: - Format helpers

    private func formatBytes(_ bytes: Int64) -> String {
        guard bytes >= 0 else { return "—" }
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f.string(fromByteCount: bytes)
    }
}

// MARK: - AnnularSector Shape (for sunburst hit testing)

struct AnnularSector: Shape {
    let startAngle : Double
    let endAngle   : Double
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let cx: CGFloat
    let cy: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: cx, y: cy), radius: outerRadius,
                    startAngle: .init(radians: startAngle), endAngle: .init(radians: endAngle), clockwise: false)
        path.addArc(center: CGPoint(x: cx, y: cy), radius: innerRadius,
                    startAngle: .init(radians: endAngle), endAngle: .init(radians: startAngle), clockwise: true)
        path.closeSubpath()
        return path
    }
}
