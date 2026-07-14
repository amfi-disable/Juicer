import SwiftUI
import UniformTypeIdentifiers

struct appuninstallerview: View {
    @StateObject private var manager = UninstallerManager()
    @State private var searchText = ""
    @State private var isDragging = false
    @State private var isShowingTerminationAlert = false
    @State private var selectedLeftoverForInfo: LeftoverItem?
    
    // Status notifications for app care actions
    @State private var careMessage: String? = nil
    @State private var isCareSuccess = true

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
                // Toolbar Search
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search installed apps...", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button(action: selectAppManually) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.plain)
                    .help("Select app bundle manually...")
                }
                .padding(10)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                
                // List of Apps (App Store-style rows)
                List(filteredApps, selection: $manager.appInfo) { app in
                    HStack(spacing: 12) {
                        Image(nsImage: app.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 36, height: 36)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.appName)
                                .font(.headline).lineLimit(1)
                            Text("v\(app.version)")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        // Small "UNINSTALL" button on the right
                        Button("UNINSTALL") {
                            manager.appInfo = app
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.red)
                    }
                    .padding(.vertical, 4)
                    .tag(app)
                }
                .listStyle(.inset)
            }
            .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 360)
            .onAppear {
                if manager.installedApps.isEmpty {
                    manager.scanInstalledApplications()
                }
            }
        } detail: {
            if let app = manager.appInfo {
                appStoreProductPage(app: app)
            } else {
                emptyDetailPlaceholder()
            }
        }
        .onChange(of: manager.appInfo) { _, newApp in
            careMessage = nil
            if let app = newApp {
                manager.scan(for: app)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.action.triggerScan"))) { notification in
            if let appURL = notification.object as? URL {
                let app = AppInfo(path: appURL)
                manager.appInfo = app
            }
        }
    }
    
    // MARK: - App Store Style Product Details
    @ViewBuilder
    private func appStoreProductPage(app: AppInfo) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header block
                HStack(spacing: 20) {
                    Image(nsImage: app.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 72, height: 72)
                        
                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.appName)
                            .font(.title).bold()
                        Text(app.bundleIdentifier)
                            .font(.subheadline).foregroundStyle(.secondary)
                        Text(app.path.path)
                            .font(.caption2).foregroundStyle(.tertiary)
                            .lineLimit(1).truncationMode(.middle)
                    }
                    
                    Spacer()
                    
                    // Unified Main Actions
                    HStack(spacing: 8) {
                        Button("OPEN APP") {
                            NSWorkspace.shared.open(app.path)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                        
                        Button("UNINSTALL") {
                            trashSelected()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .controlSize(.regular)
                        .disabled(manager.isTrashing || manager.isRunning)
                    }
                }
                
                Divider()
                
                // Status Indicators
                if let msg = careMessage {
                    HStack {
                        Image(systemName: isCareSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(isCareSuccess ? .green : .red)
                        Text(msg)
                            .font(.subheadline)
                        Spacer()
                    }
                    .padding()
                    .background((isCareSuccess ? Color.green : Color.red).opacity(0.1))
                    .cornerRadius(8)
                }

                if manager.isRunning {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Application is Active").bold().font(.subheadline)
                            Text("You should close this app before trashing its contents to avoid process locks.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Terminate Process") {
                            manager.terminateApp { success in
                                if success {
                                    careMessage = "Application terminated successfully."
                                    isCareSuccess = true
                                } else {
                                    isShowingTerminationAlert = true
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent).tint(.orange)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(8)
                    .alert("Failed to Force Close", isPresented: $isShowingTerminationAlert) {
                        Button("OK", role: .cancel) {}
                    } message: {
                        Text("This process couldn't be automatically terminated. Please quit it manually.")
                    }
                }

                // Metadata Info section
                let totalSize = manager.leftovers.reduce(0) { $0 + $1.size }
                HStack(spacing: 40) {
                    metadataStats(label: "TOTAL SIZE", value: formatBytes(totalSize))
                    Divider().frame(height: 32)
                    metadataStats(label: "VERSION", value: app.version.isEmpty ? "1.0" : app.version)
                    Divider().frame(height: 32)
                    metadataStats(label: "CATEGORY", value: app.path.path.hasPrefix("/System") ? "macOS System" : "User App")
                }
                .padding(.vertical, 8)
                
                // Companion Diagnostics & Care tools
                VStack(alignment: .leading, spacing: 12) {
                    Text("Diagnostics & App Care Companion")
                        .font(.headline)
                    Text("Troubleshoot launch issues or clear space without deleting the application binary.")
                        .font(.caption).foregroundStyle(.secondary)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        careActionCard(
                            title: "Reset Settings",
                            desc: "Trashes preferences and .plist files to repair configuration loops.",
                            icon: "arrow.counterclockwise.circle.fill",
                            color: .blue
                        ) {
                            manager.resetAppPreferences { success in
                                isCareSuccess = success
                                careMessage = success ? "Preferences reset successfully." : "Failed to remove preference files."
                            }
                        }
                        
                        careActionCard(
                            title: "Clear App Caches",
                            desc: "Purges cached logs and network storage items to reclaim storage.",
                            icon: "sparkles",
                            color: .orange
                        ) {
                            manager.clearAppCachesOnly { success in
                                isCareSuccess = success
                                careMessage = success ? "App caches purged successfully." : "Failed to clear cache folders."
                            }
                        }

                        careActionCard(
                            title: "Remove Gatekeeper Lock",
                            desc: "Strips download quarantine flags to solve unverified developer errors.",
                            icon: "shield.slash.fill",
                            color: .green
                        ) {
                            manager.stripQuarantineTag { success in
                                isCareSuccess = success
                                careMessage = success ? "Gatekeeper block stripped successfully." : "Failed to strip quarantine flags."
                            }
                        }
                    }
                }
                
                // File Breakdown Drawer (What will be deleted)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Leftovers to Delete (What will be deleted)")
                            .font(.headline)
                        Spacer()
                        Button(action: toggleAllSelection) {
                            Text(manager.leftovers.allSatisfy { $0.isSelected } ? "Deselect All" : "Select All")
                                .font(.caption).bold()
                        }
                        .buttonStyle(.link)
                    }

                    if manager.isScanning {
                        HStack(spacing: 8) {
                            ProgressView().controlSize(.small)
                            Text("Mapping files...").font(.caption).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center).padding()
                    } else {
                        VStack(spacing: 0) {
                            ForEach(manager.leftovers) { item in
                                fileBreakdownRow(item: item)
                                Divider()
                            }
                        }
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                        .cornerRadius(8)
                    }
                }
            }
            .padding(24)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }

    @ViewBuilder
    private func emptyDetailPlaceholder() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "app.badge.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary.opacity(0.6))
            Text("No App Selected")
                .font(.title2).bold().foregroundStyle(.secondary)
            Text("Select an app from the sidebar registry or drop a `.app` bundle here to review paths and perform diagnostic cleaning tasks.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Drag and Drop Area
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isDragging ? Color.accentColor : Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                .background(Color(NSColor.controlBackgroundColor).opacity(0.15))
                .frame(width: 320, height: 120)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.down.doc.fill").font(.title).foregroundStyle(isDragging ? Color.accentColor : Color.secondary)
                        Text("Drag and Drop App Here").font(.caption).bold().foregroundStyle(.secondary)
                    }
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Subcomponents

    @ViewBuilder
    private func metadataStats(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.caption2).bold().foregroundStyle(.secondary)
            Text(value).font(.title3).bold().foregroundStyle(.primary)
        }
    }

    @ViewBuilder
    private func careActionCard(title: String, desc: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: icon).foregroundColor(color).font(.headline)
                    Text(title).font(.subheadline).bold().foregroundColor(.primary)
                }
                Text(desc)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func fileBreakdownRow(item: LeftoverItem) -> some View {
        HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { item.isSelected },
                set: { value in
                    if let idx = manager.leftovers.firstIndex(where: { $0.id == item.id }) {
                        manager.leftovers[idx].isSelected = value
                    }
                }
            ))
            .toggleStyle(.checkbox)
            
            Image(systemName: item.category == "Application Bundle" ? "app" : "folder.fill")
                .foregroundColor(item.category == "Application Bundle" ? .accentColor : .orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.subheadline).bold()
                Text(item.path).font(.caption2).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
            }
            
            Spacer()
            
            Text(item.category).font(.caption).foregroundStyle(.tertiary)
            Text(formatBytes(item.size)).font(.caption).bold().foregroundStyle(.secondary).frame(width: 80, alignment: .trailing)
            
            // "Information button" to open popover details
            Button(action: {
                selectedLeftoverForInfo = item
            }) {
                Image(systemName: "info.circle")
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            .help("Show Details")
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .popover(item: $selectedLeftoverForInfo) { infoItem in
            VStack(alignment: .leading, spacing: 12) {
                Text("Leftover Breakdown Info")
                    .font(.headline).bold()
                Divider()
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Name").font(.caption).bold().foregroundStyle(.secondary)
                    Text(infoItem.name).font(.subheadline)
                    
                    Text("Category").font(.caption).bold().foregroundStyle(.secondary)
                    Text(infoItem.category).font(.subheadline).foregroundColor(.orange)
                    
                    Text("Size on Disk").font(.caption).bold().foregroundStyle(.secondary)
                    Text(formatBytes(infoItem.size)).font(.subheadline)
                    
                    Text("Full Directory Path").font(.caption).bold().foregroundStyle(.secondary)
                    Text(infoItem.path)
                        .font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(6)
                        .background(Color.secondary.opacity(0.08))
                        .cornerRadius(6)
                }
                
                Divider()
                
                HStack {
                    Button("Reveal in Finder") {
                        NSWorkspace.shared.selectFile(infoItem.path, inFileViewerRootedAtPath: "")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Spacer()
                    
                    Button("Dismiss") {
                        selectedLeftoverForInfo = nil
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .frame(width: 400)
        }
    }
    
    // MARK: - Actions
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
                careMessage = "Application and all selected support files moved to Trash."
                isCareSuccess = true
                NotificationManager.shared.sendNotification(
                    title: "Application Leftovers Removed",
                    body: "Successfully moved matched folders to Trash."
                )
                if let app = manager.appInfo {
                    manager.scan(for: app)
                }
            } else {
                careMessage = "Failed to move some support files to Trash."
                isCareSuccess = false
            }
        }
    }
    
    private func toggleAllSelection() {
        let allSelected = manager.leftovers.allSatisfy { $0.isSelected }
        for index in manager.leftovers.indices {
            manager.leftovers[index].isSelected = !allSelected
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
