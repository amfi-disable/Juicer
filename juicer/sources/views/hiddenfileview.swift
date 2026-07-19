import SwiftUI

struct hiddenfileview: View {
    @StateObject private var manager = HiddenFileManager()
    @State private var inputPath = "~"
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection()
            
            // Selection panel
            pathSelectionForm()
                .padding()

            HStack {
                Toggle("Show hidden files in Finder", isOn: Binding(get: { manager.showAllFiles }, set: { manager.toggleGlobalVisibility($0) }))
                Spacer()
                Text("Restarts Finder to apply the global setting.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            
            // List of hidden files
            if manager.isScanning {
                scanningPlaceholder()
            } else if manager.hiddenItems.isEmpty {
                emptyStatePlaceholder()
            } else {
                hiddenFilesList()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear { manager.refreshGlobalVisibility() }
    }
    
    // MARK: - Header UI
    @ViewBuilder
    private func headerSection() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hidden File Explorer")
                    .font(.title2)
                    .bold()
                Text("Scan any directory to visualize, toggle visibility, or delete hidden files and folders.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }
    
    // MARK: - Path Selector UI
    @ViewBuilder
    private func pathSelectionForm() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                TextField("Directory Path (e.g. ~, ~/Desktop)", text: $inputPath)
                    .textFieldStyle(.roundedBorder)
                
                Button("Choose Folder...") {
                    selectFolder()
                }
                .buttonStyle(.bordered)
                
                Button(action: { manager.startScan(for: inputPath) }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Scan Directory")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(inputPath.isEmpty || manager.isScanning)
            }
            
            // Quick preset suggestions
            HStack(spacing: 16) {
                Text("Presets:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Button("Home (~)") {
                    inputPath = "~"
                    manager.startScan(for: "~")
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.accentColor)
                
                Button("Desktop") {
                    inputPath = "~/Desktop"
                    manager.startScan(for: "~/Desktop")
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.accentColor)
                
                Button("Downloads") {
                    inputPath = "~/Downloads"
                    manager.startScan(for: "~/Downloads")
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.accentColor)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .cornerRadius(12)
    }
    
    // MARK: - Scanning Placeholder
    @ViewBuilder
    private func scanningPlaceholder() -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
            Text("Crawling directory paths recursively...")
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
            Image(systemName: "eye.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.6))
            Text("No Hidden Items Found")
                .font(.headline)
            Text("No files starting with '.' or matching system hidden flags were discovered in this directory.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Hidden Files List UI
    @ViewBuilder
    private func hiddenFilesList() -> some View {
        VStack(spacing: 0) {
            List {
                Section(header: listHeader()) {
                    ForEach(manager.hiddenItems) { item in
                        hiddenFileRow(item: item)
                    }
                }
            }
            .listStyle(.inset)
            
            // Summary Bar
            HStack {
                let count = manager.hiddenItems.count
                let totalSize = manager.hiddenItems.reduce(0) { $0 + $1.size }
                
                Text("Discovered \(count) hidden items (Total Size: \(formatBytes(totalSize)))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
        }
    }
    
    @ViewBuilder
    private func listHeader() -> some View {
        HStack {
            Text("File Name")
                .bold()
                .frame(width: 200, alignment: .leading)
            Text("Path")
                .bold()
            Spacer()
            Text("Type")
                .bold()
                .frame(width: 80, alignment: .leading)
            Text("Size")
                .bold()
                .frame(width: 80, alignment: .trailing)
            Text("Actions")
                .bold()
                .frame(width: 140, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func hiddenFileRow(item: HiddenFileItem) -> some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                    .foregroundColor(item.isDirectory ? .orange : .secondary)
                Text(item.name)
                    .font(.system(.body, design: .monospaced))
                    .bold()
                    .lineLimit(1)
            }
            .frame(width: 200, alignment: .leading)
            
            Text(item.path)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            
            Spacer()
            
            Text(item.isDirectory ? "Folder" : "File")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(formatBytes(item.size))
                .font(.system(.body, design: .monospaced))
                .frame(width: 80, alignment: .trailing)
            
            // Actions: Toggle flag or Trash
            HStack(spacing: 12) {
                Button(item.isHiddenByFlag ? "Unhide" : "Hide") {
                    manager.toggleVisibility(for: item) { _ in }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(role: .destructive, action: { deleteItem(item) }) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundColor(.red)
            }
            .frame(width: 140, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Actions
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Folder"
        
        if panel.runModal() == .OK, let url = panel.url {
            inputPath = url.path
            manager.startScan(for: url.path)
        }
    }
    
    private func deleteItem(_ item: HiddenFileItem) {
        let alert = NSAlert()
        alert.messageText = "Move Hidden File to Trash?"
        alert.informativeText = "Are you sure you want to move '\(item.name)' to the system Trash?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Move to Trash")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            manager.trashItem(item) { _ in }
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
