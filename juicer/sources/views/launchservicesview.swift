import SwiftUI
import UniformTypeIdentifiers

struct launchservicesview: View {
    @StateObject private var manager = LaunchServicesManager()
    @State private var searchText = ""
    
    var filteredAssociations: [GlobalAssociationItem] {
        if searchText.isEmpty {
            return manager.globalAssociations
        } else {
            return manager.globalAssociations.filter {
                $0.fileExtension.localizedCaseInsensitiveContains(searchText) ||
                $0.uti.localizedCaseInsensitiveContains(searchText) ||
                $0.handlerAppName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection()
            
            // Search / Filter Row
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search file extensions (e.g. .py, .rs, Xcode)...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
            
            // Global Associations list
            if manager.isUpdating && manager.globalAssociations.isEmpty {
                loadingPlaceholder()
            } else {
                associationsList()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            manager.loadGlobalAssociations()
        }
    }
    
    // MARK: - Header UI
    @ViewBuilder
    private func headerSection() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("File Associations Registry")
                    .font(.title2)
                    .bold()
                Text("Visualize and reassign default application handlers for common extensions in LaunchServices.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            
            Button(action: { manager.loadGlobalAssociations() }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
            }
            .buttonStyle(.bordered)
            .disabled(manager.isUpdating)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }
    
    // MARK: - Loading Indicator
    @ViewBuilder
    private func loadingPlaceholder() -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
            Text("Querying default application registry...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Associations List UI
    @ViewBuilder
    private func associationsList() -> some View {
        VStack(spacing: 0) {
            List {
                Section(header: listHeader()) {
                    ForEach(filteredAssociations) { item in
                        associationRow(item: item)
                    }
                }
            }
            .listStyle(.inset)
            
            // Summary Bar
            HStack {
                Text("Total indexed associations: \(manager.globalAssociations.count)")
                    .font(.caption)
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
            Text("Extension")
                .bold()
                .frame(width: 100, alignment: .leading)
            Text("UTI Content Type")
                .bold()
                .frame(width: 250, alignment: .leading)
            Text("Default Handler App")
                .bold()
            Spacer()
            Text("Actions")
                .bold()
                .frame(width: 120, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func associationRow(item: GlobalAssociationItem) -> some View {
        HStack {
            Text(".\(item.fileExtension.lowercased())")
                .font(.system(.body, design: .monospaced))
                .bold()
                .frame(width: 100, alignment: .leading)
            
            Text(item.uti)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(width: 250, alignment: .leading)
            
            // Handler App Name + Icon
            HStack(spacing: 8) {
                if let icon = item.handlerIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "app.dashed")
                        .foregroundColor(.secondary)
                        .frame(width: 20, height: 20)
                }
                
                Text(item.handlerAppName)
                    .bold()
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Reassign action
            let compatibleApps = manager.getCompatibleApps(for: item.uti)
            Menu {
                if !compatibleApps.isEmpty {
                    ForEach(compatibleApps, id: \.bundleIdentifier) { app in
                        Button(app.appName) {
                            _ = manager.setGlobalDefaultHandler(for: item, toApp: app.bundleIdentifier)
                        }
                    }
                    Divider()
                }
                Button("Choose other app…") {
                    selectAppForReassignment(for: item)
                }
            } label: {
                Text("Reassign")
            }
            .menuStyle(.borderlessButton)
            .frame(width: 120, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Actions
    private func selectAppForReassignment(for item: GlobalAssociationItem) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose Application"
        
        if panel.runModal() == .OK, let url = panel.url {
            let app = AppInfo(path: url)
            _ = manager.setGlobalDefaultHandler(for: item, toApp: app.bundleIdentifier)
        }
    }
}
