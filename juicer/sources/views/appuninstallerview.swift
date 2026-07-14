import SwiftUI
import UniformTypeIdentifiers

struct appuninstallerview: View {
    @StateObject private var manager = UninstallerManager()
    @State private var searchText = ""
    @State private var isDragging = false
    @State private var isShowingTerminationAlert = false
    
    var filteredApps: [AppInfo] {
        if searchText.isEmpty {
            return manager.installedApps
        } else {
            return manager.installedApps.filter {
                $0.appName.localizedCaseInsensitiveContains(searchText) ||
                $0.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Search & Manual select Toolbar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search apps...", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button(action: selectAppManually) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.plain)
                    .help("Select app from custom folder...")
                }
                .padding(10)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                
                // List of installed applications
                List(filteredApps, selection: $manager.appInfo) { app in
                    NavigationLink(value: app) {
                        HStack(spacing: 12) {
                            Image(nsImage: app.icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.appName)
                                    .font(.headline)
                                    .lineLimit(1)
                                Text(app.bundleIdentifier)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .listStyle(.sidebar)
            }
            .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 350)
            .onAppear {
                if manager.installedApps.isEmpty {
                    manager.scanInstalledApplications()
                }
            }
        } detail: {
            if let app = manager.appInfo {
                appDetailsView(app: app)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "app.badge")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary.opacity(0.8))
                        .padding(.bottom, 8)
                    Text("Select an Application")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.secondary)
                    Text("Choose any installed app from the sidebar to inspect its file paths and clean leftovers.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    // Fallback drag and drop target in the detail panel
                    VStack(spacing: 12) {
                        Text("Or drop a .app bundle here:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isDragging ? Color.accentColor : Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.1))
                            .frame(width: 260, height: 100)
                            .overlay(
                                Image(systemName: "arrow.down.doc.fill")
                                    .font(.title)
                                    .foregroundStyle(isDragging ? Color.accentColor : Color.secondary)
                            )
                            .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
                                guard let provider = providers.first else { return false }
                                _ = provider.loadObject(ofClass: URL.self) { url, error in
                                    guard let url = url, url.pathExtension.lowercased() == "app" else { return }
                                    DispatchQueue.main.async {
                                        let app = AppInfo(path: url)
                                        manager.appInfo = app
                                    }
                                }
                                return true
                            }
                    }
                    .padding(.top, 20)
                }
            }
        }
        .onChange(of: manager.appInfo) { _, newApp in
            if let app = newApp {
                manager.scan(for: app)
            }
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
                    .frame(width: 56, height: 56)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(app.appName)
                            .font(.title3)
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
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(.circular)
                    Text("Scanning directory crawl matches...")
                        .font(.headline)
                        .foregroundStyle(.secondary)
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
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Select App"
        
        if panel.runModal() == .OK, let url = panel.url {
            let app = AppInfo(path: url)
            manager.appInfo = app
        }
    }
    
    private func trashSelected() {
        manager.trashSelectedLeftovers { success in
            if success {
                AppLogger.shared.log("All selected files trashed successfully.")
                NotificationManager.shared.sendNotification(
                    title: "Application Leftovers Removed",
                    body: "Successfully removed selected support folders for \(manager.appInfo?.name ?? "the app")."
                )
                // Refresh list if still selected
                if let app = manager.appInfo {
                    manager.scan(for: app)
                }
            } else {
                AppLogger.shared.log("Some files could not be trashed.")
                NotificationManager.shared.sendNotification(
                    title: "Removal Incomplete",
                    body: "Some leftovers could not be deleted from disk."
                )
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
