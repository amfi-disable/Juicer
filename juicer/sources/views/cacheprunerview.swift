import SwiftUI

struct cacheprunerview: View {
    @StateObject private var manager = CachePrunerManager()
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection()
            
            if manager.isScanning {
                scanningPlaceholder()
            } else if manager.cacheItems.isEmpty {
                emptyStatePlaceholder()
            } else {
                cachesList()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Header UI
    @ViewBuilder
    private func headerSection() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Developer Cache Pruner")
                    .font(.title2)
                    .bold()
                Text("Scan and safely clear developer-specific cache files to instantly reclaim gigabytes of disk space.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(action: { manager.scanCaches() }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Rescan")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
            .disabled(manager.isScanning)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }
    
    // MARK: - Scanning Placeholder
    @ViewBuilder
    private func scanningPlaceholder() -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.2)
            Text("Calculating developer cache directory sizes...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State Placeholder
    @ViewBuilder
    private func emptyStatePlaceholder() -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.green)
            }
            
            VStack(spacing: 6) {
                Text("Caches are Empty")
                    .font(.headline)
                Text("No developer caches were found. Your local coding environment is fully trimmed!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - List UI
    @ViewBuilder
    private func cachesList() -> some View {
        VStack(spacing: 0) {
            List {
                Section(header: listHeader()) {
                    ForEach(manager.cacheItems) { item in
                        cacheRow(item: item)
                    }
                }
            }
            .listStyle(.inset)
            
            // Bottom Operations Bar
            HStack {
                let totalSize = manager.cacheItems.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
                let count = manager.cacheItems.filter { $0.isSelected }.count
                
                Text("\(count) targets selected (\(formatBytes(totalSize)))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button(action: pruneSelected) {
                    if manager.isPruning {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.5)
                    } else {
                        Text("Prune Selected Caches")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(count == 0 || manager.isPruning)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
        }
    }
    
    @ViewBuilder
    private func listHeader() -> some View {
        HStack {
            Button(action: toggleAllSelection) {
                Image(systemName: allSelectedStateIcon())
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            
            Text("Target Cache")
                .bold()
            Spacer()
            Text("Size")
                .bold()
                .frame(width: 100, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func cacheRow(item: PrunableCacheItem) -> some View {
        HStack(alignment: .top) {
            Toggle("", isOn: Binding(
                get: { item.isSelected },
                set: { value in
                    if let index = manager.cacheItems.firstIndex(where: { $0.id == item.id }) {
                        manager.cacheItems[index].isSelected = value
                    }
                }
            ))
            .toggleStyle(.checkbox)
            .padding(.top, 4)
            
            Image(systemName: "folder.fill")
                .foregroundStyle(.blue)
                .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                Text(item.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                Text(item.path)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.top, 2)
            }
            
            Spacer()
            
            Text(formatBytes(item.size))
                .font(.body)
                .bold()
                .frame(width: 100, alignment: .trailing)
                .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Actions
    private func pruneSelected() {
        let alert = NSAlert()
        alert.messageText = "Prune Selected Caches?"
        alert.informativeText = "Are you sure you want to delete these developer cache folders? The files will be moved to the system Trash for safety, but large projects may take longer to compile on their next build."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Prune Caches")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            manager.pruneSelectedCaches { success in
                if success {
                    AppLogger.shared.log("All selected caches pruned successfully.")
                } else {
                    AppLogger.shared.log("Some caches could not be pruned.")
                }
            }
        }
    }
    
    private func toggleAllSelection() {
        let allSelected = manager.cacheItems.allSatisfy { $0.isSelected }
        for index in manager.cacheItems.indices {
            manager.cacheItems[index].isSelected = !allSelected
        }
    }
    
    private func allSelectedStateIcon() -> String {
        let selectedCount = manager.cacheItems.filter { $0.isSelected }.count
        if selectedCount == 0 {
            return "square"
        } else if selectedCount == manager.cacheItems.count {
            return "checkmark.square.fill"
        } else {
            return "minus.square.fill"
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
