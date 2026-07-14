import SwiftUI

struct orphanscannerview: View {
    @StateObject private var manager = OrphanScannerManager()
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection()
            
            if manager.isScanning {
                scanningPlaceholder()
            } else if manager.orphans.isEmpty {
                emptyStatePlaceholder()
            } else {
                orphansList()
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
                Text("Orphan Finder")
                    .font(.title2)
                    .bold()
                Text("Scan and remove leftovers from applications that are no longer installed on your Mac.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(action: { manager.scanOrphans() }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Scan Now")
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
    
    // MARK: - Scanning Indicator UI
    @ViewBuilder
    private func scanningPlaceholder() -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.2)
            Text("Scanning Library support directories...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State UI
    @ViewBuilder
    private func emptyStatePlaceholder() -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.green)
            }
            
            VStack(spacing: 6) {
                Text("No Orphans Found")
                    .font(.headline)
                Text("Your Library directories are fully clean of uninstalled app leftovers!")
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
    private func orphansList() -> some View {
        VStack(spacing: 0) {
            List {
                Section(header: listHeader()) {
                    ForEach(manager.orphans) { item in
                        orphanRow(item: item)
                    }
                }
            }
            .listStyle(.inset)
            
            // Bottom Operations Bar
            HStack {
                let totalSize = manager.orphans.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
                let count = manager.orphans.filter { $0.isSelected }.count
                
                Text("\(count) orphaned folders selected (\(formatBytes(totalSize)))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button(action: trashSelected) {
                    if manager.isTrashing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.5)
                    } else {
                        Text("Move Selected to Trash")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(count == 0 || manager.isTrashing)
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
            
            Text("Orphaned Folder Path")
                .bold()
            Spacer()
            Text("Category")
                .bold()
                .frame(width: 150, alignment: .leading)
            Text("Size")
                .bold()
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func orphanRow(item: LeftoverItem) -> some View {
        HStack {
            Toggle("", isOn: Binding(
                get: { item.isSelected },
                set: { value in
                    if let index = manager.orphans.firstIndex(where: { $0.id == item.id }) {
                        manager.orphans[index].isSelected = value
                    }
                }
            ))
            .toggleStyle(.checkbox)
            
            Image(systemName: "folder.badge.minus")
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                Text(item.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            Text(item.category)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 150, alignment: .leading)
            
            Text(formatBytes(item.size))
                .font(.subheadline)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, 2)
    }
    
    // MARK: - Actions
    private func trashSelected() {
        manager.trashSelectedOrphans { success in
            if success {
                AppLogger.shared.log("All selected orphans trashed successfully.")
            } else {
                AppLogger.shared.log("Some orphans could not be trashed.")
            }
        }
    }
    
    private func toggleAllSelection() {
        let allSelected = manager.orphans.allSatisfy { $0.isSelected }
        for index in manager.orphans.indices {
            manager.orphans[index].isSelected = !allSelected
        }
    }
    
    private func allSelectedStateIcon() -> String {
        let selectedCount = manager.orphans.filter { $0.isSelected }.count
        if selectedCount == 0 {
            return "square"
        } else if selectedCount == manager.orphans.count {
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
