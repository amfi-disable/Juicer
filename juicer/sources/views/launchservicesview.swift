import SwiftUI

struct launchservicesview: View {
    @StateObject private var manager = LaunchServicesManager()
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection()
            
            if let app = manager.selectedApp {
                appDetailsAndExtensionsView(app: app)
            } else {
                selectAppPlaceholder()
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
                Text("File Associations Override")
                    .font(.title2)
                    .bold()
                Text("Reassign default applications for file extensions by interfacing with LaunchServices.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }
    
    // MARK: - Select App Placeholder UI
    @ViewBuilder
    private func selectAppPlaceholder() -> some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "doc.badge.gearshape")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.accentColor)
            }
            
            VStack(spacing: 6) {
                Text("Select an Application")
                    .font(.headline)
                Text("Choose any text editor, IDE, or utility to view and override its file associations.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button("Select Application...") {
                selectAppManually()
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Details & Extensions Table UI
    @ViewBuilder
    private func appDetailsAndExtensionsView(app: AppInfo) -> some View {
        VStack(spacing: 0) {
            // App Metadata Row
            HStack(spacing: 16) {
                Image(nsImage: app.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(app.appName)
                            .font(.headline)
                            .bold()
                        Text("v\(app.version)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(app.bundleIdentifier)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button("Change App...", action: selectAppManually)
                    .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.3))
            
            // List of supported file types
            if manager.fileTypes.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 6)
                    Text("No Declared File Extensions")
                        .font(.headline)
                    Text("This application does not declare any document types in its Info.plist bundle.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section(header: listHeader()) {
                        ForEach(manager.fileTypes) { item in
                            fileTypeRow(item: item, app: app)
                        }
                    }
                }
                .listStyle(.inset)
                
                // Bottom Batch Operation Bar
                HStack {
                    let totalCount = manager.fileTypes.count
                    let defaultCount = manager.fileTypes.filter { $0.isCurrentlyDefault }.count
                    
                    Text("\(defaultCount) of \(totalCount) types currently bound to \(app.appName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button("Make Default for All Supported Types") {
                        makeDefaultForAll(app: app)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                    .disabled(defaultCount == totalCount)
                }
                .padding()
                .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            }
        }
    }
    
    @ViewBuilder
    private func listHeader() -> some View {
        HStack {
            Text("File Extension")
                .bold()
                .frame(width: 120, alignment: .leading)
            Text("UTI Type Identifier")
                .bold()
            Spacer()
            Text("Status")
                .bold()
                .frame(width: 140, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func fileTypeRow(item: AssociatedFileType, app: AppInfo) -> some View {
        HStack {
            Text(".\(item.fileExtension.lowercased())")
                .font(.system(.body, design: .monospaced))
                .bold()
                .frame(width: 120, alignment: .leading)
            
            Text(item.uti)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            HStack {
                if item.isCurrentlyDefault {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Default Handler")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    .padding(.trailing, 8)
                } else {
                    Button("Assign Handler") {
                        _ = manager.setAsDefaultHandler(for: item, appBundleId: app.bundleIdentifier)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .frame(width: 140, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Actions
    private func selectAppManually() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Select App"
        
        if panel.runModal() == .OK, let url = panel.url {
            let app = AppInfo(path: url)
            manager.loadFileTypes(for: app)
        }
    }
    
    private func makeDefaultForAll(app: AppInfo) {
        manager.isUpdating = true
        
        Task.detached(priority: .userInitiated) {
            let nonDefaultItems = await MainActor.run {
                manager.fileTypes.filter { !$0.isCurrentlyDefault }
            }
            
            for item in nonDefaultItems {
                _ = manager.setAsDefaultHandler(for: item, appBundleId: app.bundleIdentifier)
            }
            
            await MainActor.run {
                manager.loadFileTypes(for: app)
                manager.isUpdating = false
                AppLogger.shared.log("Completed batch associations override for \(app.appName).")
            }
        }
    }
}
