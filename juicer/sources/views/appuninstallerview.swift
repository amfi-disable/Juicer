import SwiftUI
import UniformTypeIdentifiers

struct appuninstallerview: View {
    @StateObject private var manager = UninstallerManager()
    @State private var isDragging = false
    @State private var isShowingTerminationAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            if let app = manager.appInfo {
                appDetailsView(app: app)
            } else {
                dragAndDropPlaceholder()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Drag and Drop Landing UI
    @ViewBuilder
    private func dragAndDropPlaceholder() -> some View {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(isDragging ? Color.accentColor.opacity(0.15) : Color(NSColor.controlBackgroundColor).opacity(0.3))
                    .frame(width: 320, height: 220)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(
                                isDragging ? Color.accentColor : Color.secondary.opacity(0.3),
                                style: StrokeStyle(lineWidth: 2, dash: isDragging ? [] : [8])
                            )
                    )
                
                VStack(spacing: 16) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(isDragging ? Color.accentColor : Color.secondary)
                        .scaleEffect(isDragging ? 1.1 : 1.0)
                        .animation(.spring(), value: isDragging)
                    
                    VStack(spacing: 4) {
                        Text("Drag & Drop Application")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Drop any .app bundle here to scan leftovers")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
                guard let provider = providers.first else { return false }
                
                _ = provider.loadObject(ofClass: URL.self) { url, error in
                    guard let url = url, url.pathExtension.lowercased() == "app" else {
                        AppLogger.shared.log("Dropped item is not a .app bundle.")
                        return
                    }
                    
                    DispatchQueue.main.async {
                        let app = AppInfo(path: url)
                        manager.scan(for: app)
                    }
                }
                return true
            }
            
            // Choose app manual button
            Button(action: selectAppManually) {
                HStack {
                    Image(systemName: "folder.fill")
                    Text("Select App Manually...")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
        }
    }
    
    // MARK: - Details & Leftovers Listing UI
    @ViewBuilder
    private func appDetailsView(app: AppInfo) -> some View {
        VStack(spacing: 0) {
            // Top Bar / App Info Header
            HStack(spacing: 16) {
                Image(nsImage: app.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(app.appName)
                            .font(.title2)
                            .bold()
                        Text("v\(app.version)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(app.bundleIdentifier)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(app.path.path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                Spacer()
                
                Button(action: { manager.appInfo = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            
            // Running Alert Banner if app is active
            if manager.isRunning {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("This application is currently running.")
                        .font(.subheadline)
                    Spacer()
                    Button("Terminate App") {
                        manager.terminateApp { success in
                            if !success {
                                isShowingTerminationAlert = true
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color.orange.opacity(0.15))
                .alert("Failed to Terminate App", isPresented: $isShowingTerminationAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("We couldn't terminate the app. Please force quit it manually from Activity Monitor or Dock.")
                }
            }
            
            // Leftovers List
            if manager.isScanning {
                VStack {
                    ProgressView("Scanning for leftovers...")
                        .progressViewStyle(.circular)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section(header: listHeader()) {
                        ForEach(manager.leftovers) { item in
                            leftoverRow(item: item)
                        }
                    }
                }
                .listStyle(.inset)
                
                // Bottom Operations Bar
                HStack {
                    let totalSize = manager.leftovers.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
                    let count = manager.leftovers.filter { $0.isSelected }.count
                    
                    Text("\(count) items selected (\(formatBytes(totalSize)))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button("Cancel", action: { manager.appInfo = nil })
                        .buttonStyle(.bordered)
                    
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
                    .disabled(count == 0 || manager.isTrashing || manager.isRunning)
                }
                .padding()
                .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            }
        }
    }
    
    // MARK: - Row and Header Helpers
    @ViewBuilder
    private func listHeader() -> some View {
        HStack {
            Button(action: toggleAllSelection) {
                Image(systemName: allSelectedStateIcon())
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            
            Text("Leftover Path")
                .bold()
            Spacer()
            Text("Type")
                .bold()
                .frame(width: 150, alignment: .leading)
            Text("Size")
                .bold()
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func leftoverRow(item: LeftoverItem) -> some View {
        HStack {
            Toggle("", isOn: Binding(
                get: { item.isSelected },
                set: { value in
                    if let index = manager.leftovers.firstIndex(where: { $0.id == item.id }) {
                        manager.leftovers[index].isSelected = value
                    }
                }
            ))
            .toggleStyle(.checkbox)
            
            // File icon representation
            Image(systemName: item.category == "Application Bundle" ? "app" : "folder.fill")
                .foregroundStyle(item.category == "Application Bundle" ? Color.accentColor : Color.orange)
            
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
    
    // MARK: - Action Functions
    private func selectAppManually() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Select App"
        
        if panel.runModal() == .OK, let url = panel.url {
            let app = AppInfo(path: url)
            manager.scan(for: app)
        }
    }
    
    private func trashSelected() {
        manager.trashSelectedLeftovers { success in
            if success {
                AppLogger.shared.log("All selected files trashed successfully.")
            } else {
                AppLogger.shared.log("Some files could not be trashed.")
            }
        }
    }
    
    private func toggleAllSelection() {
        let allSelected = manager.leftovers.allSatisfy { $0.isSelected }
        for index in manager.leftovers.indices {
            manager.leftovers[index].isSelected = !allSelected
        }
    }
    
    private func allSelectedStateIcon() -> String {
        let selectedCount = manager.leftovers.filter { $0.isSelected }.count
        if selectedCount == 0 {
            return "square"
        } else if selectedCount == manager.leftovers.count {
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
