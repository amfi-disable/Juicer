import SwiftUI

struct largefilesview: View {
    @StateObject private var manager = LargeFilesManager()
    
    private let sizeOptions: [Double] = [50, 100, 250, 500, 1000]
    private let ageOptions: [Int] = [1, 3, 6, 12, 24]
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection()
            
            // Filters Selector Panel
            filtersPanel()
                .padding()
            
            // List of matching files
            if manager.isScanning && manager.largeFiles.isEmpty {
                scanningPlaceholder()
            } else if manager.largeFiles.isEmpty {
                emptyStatePlaceholder()
            } else {
                filesList()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            manager.startScan()
        }
    }
    
    // MARK: - Header UI
    @ViewBuilder
    private func headerSection() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Large & Old Files Finder")
                    .font(.title2)
                    .bold()
                Text("Scan Downloads, Documents, and Desktop folders to identify and remove space-consuming files.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }
    
    // MARK: - Filters Panel UI
    @ViewBuilder
    private func filtersPanel() -> some View {
        HStack(spacing: 24) {
            // Size Threshold Selector
            HStack(spacing: 8) {
                Text("Size Greater Than:")
                    .font(.subheadline)
                    .bold()
                Picker("", selection: $manager.sizeThresholdMB) {
                    ForEach(sizeOptions, id: \.self) { size in
                        Text(formatMB(size)).tag(size)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)
            }
            
            // Age Threshold Selector
            HStack(spacing: 8) {
                Text("Or Age Older Than:")
                    .font(.subheadline)
                    .bold()
                Picker("", selection: $manager.ageThresholdMonths) {
                    ForEach(ageOptions, id: \.self) { months in
                        Text("\(months) Month\(months > 1 ? "s" : "")").tag(months)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 130)
            }
            
            Spacer()
            
            Button(action: { manager.startScan() }) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Scan Files")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(manager.isScanning)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .cornerRadius(12)
        .onChange(of: manager.sizeThresholdMB) { _, _ in manager.startScan() }
        .onChange(of: manager.ageThresholdMonths) { _, _ in manager.startScan() }
    }
    
    // MARK: - Scanning Placeholder
    @ViewBuilder
    private func scanningPlaceholder() -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
            Text("Crawling user folders for file metrics...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State UI
    @ViewBuilder
    private func emptyStatePlaceholder() -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "doc.badge.ellipsis")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.6))
            Text("No Space-Wasting Files Found")
                .font(.headline)
            Text("No files met your configured size or age threshold filters.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Files List UI
    @ViewBuilder
    private func filesList() -> some View {
        VStack(spacing: 0) {
            List {
                Section(header: listHeader()) {
                    ForEach(manager.largeFiles) { item in
                        fileRow(item: item)
                    }
                }
            }
            .listStyle(.inset)
            
            // Bottom Operations Bar
            HStack {
                let totalSize = manager.largeFiles.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
                let count = manager.largeFiles.filter { $0.isSelected }.count
                
                Text("\(count) files selected (\(formatBytes(totalSize)))")
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
            
            Text("File Name")
                .bold()
                .frame(width: 250, alignment: .leading)
            Text("Path Location")
                .bold()
            Spacer()
            Text("Last Modified")
                .bold()
                .frame(width: 140, alignment: .leading)
            Text("Size")
                .bold()
                .frame(width: 100, alignment: .trailing)
            Text("Actions")
                .bold()
                .frame(width: 100, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func fileRow(item: LargeFileItem) -> some View {
        HStack {
            Toggle("", isOn: Binding(
                get: { item.isSelected },
                set: { value in
                    if let index = manager.largeFiles.firstIndex(where: { $0.id == item.id }) {
                        manager.largeFiles[index].isSelected = value
                    }
                }
            ))
            .toggleStyle(.checkbox)
            
            HStack(spacing: 8) {
                Image(systemName: "doc.fill")
                    .foregroundColor(.secondary)
                Text(item.name)
                    .bold()
                    .lineLimit(1)
            }
            .frame(width: 250, alignment: .leading)
            
            Text(item.path)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            
            Spacer()
            
            Text(formatDate(item.modificationDate))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 140, alignment: .leading)
            
            Text(formatBytes(item.size))
                .font(.system(.body, design: .monospaced))
                .frame(width: 100, alignment: .trailing)
            
            Button("Reveal") {
                NSWorkspace.shared.selectFile(item.path, inFileViewerRootedAtPath: "")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .frame(width: 100, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Actions
    private func trashSelected() {
        let count = manager.largeFiles.filter { $0.isSelected }.count
        let alert = NSAlert()
        alert.messageText = "Trash \(count) Large Files?"
        alert.informativeText = "Are you sure you want to move the selected files to the system Trash?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Move to Trash")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            manager.trashSelectedItems { success in
                if success {
                    AppLogger.shared.log("Successfully moved selected large files to Trash.")
                } else {
                    AppLogger.shared.log("Some files could not be trashed.")
                }
            }
        }
    }
    
    private func toggleAllSelection() {
        let allSelected = manager.largeFiles.allSatisfy { $0.isSelected }
        for index in manager.largeFiles.indices {
            manager.largeFiles[index].isSelected = !allSelected
        }
    }
    
    private func allSelectedStateIcon() -> String {
        let selectedCount = manager.largeFiles.filter { $0.isSelected }.count
        if selectedCount == 0 {
            return "square"
        } else if selectedCount == manager.largeFiles.count {
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
    
    private func formatMB(_ mb: Double) -> String {
        if mb >= 1000 {
            return String(format: "%.0f GB", mb / 1000.0)
        } else {
            return "\(Int(mb)) MB"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
