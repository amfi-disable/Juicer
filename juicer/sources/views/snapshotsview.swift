import SwiftUI

struct snapshotsview: View {
    @State private var snapshots: [DiagnosticSnapshot] = []
    @State private var firstSelected: DiagnosticSnapshot? = nil
    @State private var secondSelected: DiagnosticSnapshot? = nil
    @State private var diffResults: [SnapshotDiff] = []
    @State private var isDiffing = false
    
    var body: some View {
        VStack(spacing: 0) {
            headerBar()
            Divider()
            
            HSplitView {
                // Left Column: List of Snapshots
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Past Snapshots").font(.headline)
                        Spacer()
                        Button(action: takeSnapshot) {
                            Label("New Snapshot", systemImage: "camera.shutter.button.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.15))
                    
                    Divider()
                    
                    if snapshots.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "camera.viewfinder").font(.system(size: 36)).foregroundStyle(.secondary)
                            Text("No snapshots recorded yet.").font(.subheadline).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(snapshots) { snap in
                                snapshotRow(snap: snap)
                            }
                        }
                        .listStyle(.inset)
                    }
                }
                .frame(minWidth: 320, idealWidth: 360, maxWidth: 400)
                
                // Right Column: Diff Inspector
                VStack(spacing: 0) {
                    if let first = firstSelected, let second = secondSelected {
                        diffPanel(current: first, older: second)
                    } else {
                        diffSelectionPlaceholder()
                    }
                }
                .frame(minWidth: 400, maxWidth: .infinity)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            loadSnapshots()
        }
    }
    
    @ViewBuilder
    private func headerBar() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Diagnostic Snapshots")
                    .font(.title2).bold()
                Text("Capture hosts rules, launch daemons, active DNS and Homebrew packages to trace system changes.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
    }
    
    @ViewBuilder
    private func snapshotRow(snap: DiagnosticSnapshot) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(formatDate(snap.timestamp)).font(.headline)
                Text("\(snap.installedCasks.count) Casks | \(snap.launchDaemons.count) Daemons | \(snap.hostsLines.count) Hosts Rules")
                    .font(.caption).foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Buttons to select for comparison
            HStack(spacing: 6) {
                Button("1st") {
                    firstSelected = snap
                    calculateDiff()
                }
                .buttonStyle(.bordered)
                .tint(firstSelected?.id == snap.id ? .blue : nil)
                .help("Select as current state for comparison")
                
                Button("2nd") {
                    secondSelected = snap
                    calculateDiff()
                }
                .buttonStyle(.bordered)
                .tint(secondSelected?.id == snap.id ? .orange : nil)
                .help("Select as base/older state for comparison")
                
                Button(action: { deleteSnapshot(snap) }) {
                    Image(systemName: "trash").foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
    }
    
    @ViewBuilder
    private func diffPanel(current: DiagnosticSnapshot, older: DiagnosticSnapshot) -> some View {
        VStack(spacing: 0) {
            // Diff Header
            VStack(alignment: .leading, spacing: 10) {
                Text("System Changes Comparison").font(.headline)
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading) {
                        Text("Current State:").font(.caption).bold().foregroundStyle(.blue)
                        Text(formatDate(current.timestamp)).font(.subheadline)
                    }
                    Image(systemName: "arrow.left.arrow.right").foregroundStyle(.secondary)
                    VStack(alignment: .leading) {
                        Text("Base State (Older):").font(.caption).bold().foregroundStyle(.orange)
                        Text(formatDate(older.timestamp)).font(.subheadline)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
            
            Divider()
            
            // Diff Table List
            if diffResults.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 40)).foregroundColor(.green)
                    Text("No differences detected.").font(.headline)
                    Text("Both snapshots match exactly on hosts, DNS, and packages.").font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(diffResults) { item in
                    HStack(spacing: 12) {
                        // Action Badge
                        Text(item.action.uppercased())
                            .font(.caption2).bold()
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(item.action == "Added" ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                            .foregroundColor(item.action == "Added" ? .green : .red)
                            .cornerRadius(4)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.detail).font(.system(.body, design: .monospaced)).lineLimit(1)
                            Text(item.category).font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.inset)
            }
        }
    }
    
    @ViewBuilder
    private func diffSelectionPlaceholder() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.triangle.2.circlepath.camera")
                .font(.system(size: 48)).foregroundStyle(.secondary)
            Text("Select Snapshots to Compare").font(.headline).foregroundStyle(.secondary)
            Text("Click '1st' to set the target snapshot, and '2nd' to select the base snapshot to perform side-by-side verification.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func loadSnapshots() {
        snapshots = DiagnosticSnapshot.loadAll()
    }
    
    private func takeSnapshot() {
        let snap = DiagnosticSnapshot.captureCurrentState()
        snap.save()
        loadSnapshots()
        AppLogger.shared.log("Recorded diagnostic state snapshot.")
    }
    
    private func deleteSnapshot(_ snap: DiagnosticSnapshot) {
        DiagnosticSnapshot.delete(snap)
        if firstSelected?.id == snap.id { firstSelected = nil }
        if secondSelected?.id == snap.id { secondSelected = nil }
        loadSnapshots()
        calculateDiff()
    }
    
    private func calculateDiff() {
        guard let first = firstSelected, let second = secondSelected else {
            diffResults = []
            return
        }
        diffResults = first.diff(against: second)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}
