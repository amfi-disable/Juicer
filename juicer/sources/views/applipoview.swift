import SwiftUI

struct applipoview: View {
    @StateObject private var manager = AppLipoManager()
    @State private var searchText = ""
    
    var filteredApps: [LipoAppItem] {
        if searchText.isEmpty {
            return manager.universalApps
        } else {
            return manager.universalApps.filter {
                $0.appName.localizedCaseInsensitiveContains(searchText) ||
                $0.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection()
            
            // Search / Filter row
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search universal applications...", text: $searchText)
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
            
            // List of universal applications
            if manager.isScanning && manager.universalApps.isEmpty {
                scanningPlaceholder()
            } else if manager.universalApps.isEmpty {
                emptyStatePlaceholder()
            } else {
                appsList()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            manager.scanForUniversalApps()
        }
    }
    
    // MARK: - Header UI
    @ViewBuilder
    private func headerSection() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("App Lipo Slicer")
                    .font(.title2)
                    .bold()
                Text("Strip non-native CPU architectures (e.g. Intel x86_64 on Apple Silicon) from Universal binaries to save storage space.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            
            Button(action: { manager.scanForUniversalApps() }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Rescan")
                }
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
            Text("Scanning executable headers for FAT binaries...")
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
            Image(systemName: "cpu")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.6))
            Text("No Universal Applications Found")
                .font(.headline)
            Text("All installed applications are already optimized for your CPU architecture.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Applications List
    @ViewBuilder
    private func appsList() -> some View {
        VStack(spacing: 0) {
            List {
                Section(header: listHeader()) {
                    ForEach(filteredApps) { item in
                        appRow(item: item)
                    }
                }
            }
            .listStyle(.inset)
            
            // Total Savings Bar
            HStack {
                let totalSavings = manager.universalApps.reduce(0) { $0 + $1.estimatedSavings }
                Text("Total potential storage recovery: \(formatBytes(totalSavings)) across \(manager.universalApps.count) apps.")
                    .font(.subheadline)
                    .bold()
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
            Text("Application")
                .bold()
                .frame(width: 240, alignment: .leading)
            Text("Architectures Packed")
                .bold()
                .frame(width: 250, alignment: .leading)
            Text("Current Size")
                .bold()
                .frame(width: 100, alignment: .trailing)
            Spacer()
            Text("Est. Savings")
                .bold()
                .frame(width: 100, alignment: .trailing)
            Text("Action")
                .bold()
                .frame(width: 120, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func appRow(item: LipoAppItem) -> some View {
        HStack {
            // Icon & Name
            HStack(spacing: 12) {
                Image(nsImage: item.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.appName)
                        .font(.headline)
                        .lineLimit(1)
                    Text(item.bundleIdentifier)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(width: 240, alignment: .leading)
            
            // Architectures
            Text(item.architectures.joined(separator: " + "))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 250, alignment: .leading)
            
            // Current Size
            Text(formatBytes(item.totalSize))
                .font(.system(.body, design: .monospaced))
                .frame(width: 100, alignment: .trailing)
            
            Spacer()
            
            // Estimated savings
            Text(formatBytes(item.estimatedSavings))
                .font(.system(.body, design: .monospaced))
                .bold()
                .foregroundColor(.green)
                .frame(width: 100, alignment: .trailing)
            
            // Action
            Button(item.isThinned ? "Thinned" : "Thin App") {
                confirmThinning(for: item)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
            .controlSize(.small)
            .disabled(item.isThinned || manager.isThinning)
            .frame(width: 120, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Actions
    private func confirmThinning(for item: LipoAppItem) {
        let alert = NSAlert()
        alert.messageText = "Thin Universal Application?"
        alert.informativeText = "Are you sure you want to slice '\(item.appName)'? This will permanently strip the non-native architectures from the binary. It cannot be undone without re-installing the app."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Thin Application")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            manager.thinApplication(item) { _ in }
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
