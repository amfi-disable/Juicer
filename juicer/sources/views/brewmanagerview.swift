import SwiftUI

struct brewmanagerview: View {
    @StateObject private var manager = BrewManager()
    @State private var searchText = ""
    @State private var selectedTab = 0 
    // 0: Packages, 1: Services, 2: Taps, 3: Diagnostics/Maintenance, 4: Brewfile Sync
    
    @State private var typeFilter = 0 // 0: All, 1: Formulae, 2: Casks
    @State private var stateFilter = 0 // 0: All, 1: Pinned, 2: Linked, 3: Unlinked, 4: Outdated, 5: Leaf/Intentional
    @State private var isProcessing = false
    @State private var statusMessage = ""
    
    @State private var selectedPackageForInfo: BrewPackage?
    @State private var detailedInfoText = ""
    @State private var isLoadingInfo = false
    
    // Dependency Tree Sheet state
    @State private var selectedPackageForTree: BrewPackage?
    
    // Diagnostics State
    @State private var dryRunOutput = ""
    @State private var isRunningDryRun = false
    @State private var autoremoveOutput = ""
    @State private var isRunningAutoremove = false
    
    var filteredPackages: [BrewPackage] {
        var list = manager.packages
        
        // Type filter
        if typeFilter == 1 {
            list = list.filter { $0.type == .formula }
        } else if typeFilter == 2 {
            list = list.filter { $0.type == .cask }
        }
        
        // State filter
        if stateFilter == 1 {
            list = list.filter { $0.isPinned }
        } else if stateFilter == 2 {
            list = list.filter { $0.isLinked }
        } else if stateFilter == 3 {
            list = list.filter { !$0.isLinked }
        } else if stateFilter == 4 {
            list = list.filter { $0.isOutdated }
        } else if stateFilter == 5 {
            list = list.filter { $0.isLeaf }
        }
        
        // Search text
        if !searchText.isEmpty {
            list = list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return list
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if BrewManager.brewPath == nil {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text("Homebrew Not Found")
                        .font(.title2)
                        .bold()
                    Text("Juicer could not locate the 'brew' executable at typical installation paths (/opt/homebrew or /usr/local/bin). Please install Homebrew to use this module.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Header Segment bar
                HStack(spacing: 12) {
                    Picker("", selection: $selectedTab) {
                        Text("Packages").tag(0)
                        Text("Services").tag(1)
                        Text("Taps").tag(2)
                        Text("Maintenance").tag(3)
                        Text("Brewfile Sync").tag(4)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 600)
                    
                    Spacer()
                    
                    if selectedTab == 0 {
                        if manager.isLoading {
                            ProgressView().controlSize(.small)
                        } else {
                            Button(action: { manager.loadPackages() }) {
                                Image(systemName: "arrow.clockwise")
                            }
                            .buttonStyle(.bordered)
                            .help("Refresh Packages List")
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.windowBackgroundColor).opacity(0.3))
                
                Divider()
                
                // Tab Router
                switch selectedTab {
                case 0:
                    packagesTab()
                case 1:
                    brewservicesview()
                case 2:
                    brewtapsview()
                case 3:
                    maintenanceTab()
                case 4:
                    brewfilesyncview()
                default:
                    EmptyView()
                }
                
                // Status message bar
                if !statusMessage.isEmpty {
                    HStack {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Dismiss") { statusMessage = "" }
                            .buttonStyle(.plain)
                            .foregroundColor(.accentColor)
                    }
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                }
            }
        }
        .onAppear {
            if BrewManager.brewPath != nil {
                manager.loadPackages()
            }
        }
        .sheet(item: $selectedPackageForInfo) { package in
            packageInfoSheet(package)
        }
        .sheet(item: $selectedPackageForTree) { package in
            DependencyTreeView(packageName: package.name, packages: manager.packages) {
                selectedPackageForTree = nil
            }
        }
    }
    
    // MARK: - Packages View Tab
    @ViewBuilder
    private func packagesTab() -> some View {
        VStack(spacing: 0) {
            // Filters bar
            HStack(spacing: 12) {
                Picker("Type", selection: $typeFilter) {
                    Text("All Types").tag(0)
                    Text("Formulae").tag(1)
                    Text("Casks").tag(2)
                }
                .frame(width: 160)
                
                Picker("State", selection: $stateFilter) {
                    Text("All States").tag(0)
                    Text("Pinned").tag(1)
                    Text("Linked").tag(2)
                    Text("Unlinked").tag(3)
                    Text("Outdated").tag(4)
                    Text("Leaf/Intentional").tag(5)
                }
                .frame(width: 180)
                
                Spacer()
                
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search package...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.1))
            
            Divider()
            
            // List / Table view
            if manager.isLoading {
                VStack {
                    ProgressView("Scanning installed packages...")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredPackages.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No Matching Packages Found")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredPackages) { package in
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(package.type == .cask ? Color.blue.opacity(0.15) : Color.orange.opacity(0.15))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: package.type == .cask ? "macwindow" : "terminal.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(package.type == .cask ? Color.blue : Color.orange)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(package.name)
                                    .font(.headline)
                                
                                Button(action: { self.selectedPackageForInfo = package }) {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.accentColor)
                                }
                                .buttonStyle(.plain)
                                .help("View Package Details")
                                
                                // Tag badges
                                if package.isPinned {
                                    Label("Pinned", systemImage: "pin.fill")
                                        .font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Color.red.opacity(0.15))
                                        .foregroundColor(.red)
                                        .cornerRadius(4)
                                }
                                
                                if !package.isLinked {
                                    Label("Unlinked", systemImage: "link.badge.plus")
                                        .font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Color.gray.opacity(0.15))
                                        .foregroundColor(.gray)
                                        .cornerRadius(4)
                                }
                                
                                if package.isLeaf {
                                    Label("Leaf / Intentional", systemImage: "leaf.fill")
                                        .font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Color.green.opacity(0.15))
                                        .foregroundColor(.green)
                                        .cornerRadius(4)
                                }
                            }
                            
                            HStack(spacing: 8) {
                                Text("Installed: \(package.version)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if package.isOutdated, let latest = package.latestVersion {
                                    Image(systemName: "arrow.right")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                    Text("Latest: \(latest)")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                        .bold()
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Action buttons
                        HStack(spacing: 8) {
                            if package.isOutdated {
                                Button("Upgrade") {
                                    upgradePackage(package)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                                .disabled(isProcessing)
                            }
                            
                            // Context actions menu
                            Menu {
                                if package.type == .formula {
                                    if package.isPinned {
                                        Button("Unpin Version") { unpinPackage(package) }
                                    } else {
                                        Button("Pin Version") { pinPackage(package) }
                                    }
                                    
                                    if package.isLinked {
                                        Button("Unlink Binary Paths") { unlinkPackage(package) }
                                    } else {
                                        Button("Link Binary Paths") { linkPackage(package) }
                                    }
                                    
                                    if !package.dependencies.isEmpty {
                                        Button("View Dependency Tree...") {
                                            selectedPackageForTree = package
                                        }
                                    }
                                }
                                
                                Button("Uninstall Package", role: .destructive) {
                                    uninstallPackage(package)
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                            .menuStyle(.borderlessButton)
                            .frame(width: 32)
                        }
                    }
                    .padding(.vertical, 4)
                    Divider()
                }
                .listStyle(.plain)
            }
        }
    }
    
    // MARK: - Maintenance Tab View
    @ViewBuilder
    private func maintenanceTab() -> some View {
        HStack(spacing: 20) {
            // Left column: Doctor + Autoremove
            VStack(spacing: 20) {
                // Doctor Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "stethoscope")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("Brew Doctor")
                            .font(.headline)
                            .bold()
                        Spacer()
                        if manager.isRunningDoctor {
                            ProgressView().controlSize(.small)
                        } else {
                            Button("Run Doctor") {
                                manager.runDoctor()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    ScrollView {
                        Text(manager.doctorOutput.isEmpty ? "Check your Homebrew configuration health." : manager.doctorOutput)
                            .font(.system(.caption, design: .monospaced))
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                    )
                }
                .frame(maxHeight: .infinity)
                
                // Autoremove Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "trash.slash.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                        Text("Autoremove Leaves")
                            .font(.headline)
                            .bold()
                        Spacer()
                        if isRunningAutoremove {
                            ProgressView().controlSize(.small)
                        } else {
                            Button("Remove Orphans") {
                                runAutoremove()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    ScrollView {
                        Text(autoremoveOutput.isEmpty ? "Prune orphaned packages installed automatically as sub-dependencies but no longer needed by any active tools." : autoremoveOutput)
                            .font(.system(.caption, design: .monospaced))
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                    )
                }
                .frame(maxHeight: .infinity)
            }
            
            // Right column: Dry Run Cleanup
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "broom.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text("Downloads Cache Cleanup")
                        .font(.headline)
                        .bold()
                    Spacer()
                    
                    HStack(spacing: 8) {
                        if isRunningDryRun {
                            ProgressView().controlSize(.small)
                        } else {
                            Button("Scan Cache (Dry Run)") {
                                runDryRunCleanup()
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        if manager.isRunningCleanup {
                            ProgressView().controlSize(.small)
                        } else {
                            Button("Confirm Cleanup") {
                                manager.runCleanup()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                        }
                    }
                }
                
                ScrollView {
                    Text(dryRunOutput.isEmpty ? "Estimate cached download file capacities and old logs that can be swept. Running 'Confirm' purges Homebrew downloads." : dryRunOutput)
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                )
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }
    
    // MARK: - Package Info Sheet
    @ViewBuilder
    private func packageInfoSheet(_ package: BrewPackage) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: package.type == .cask ? "macwindow" : "terminal.fill")
                    .font(.title)
                    .foregroundColor(package.type == .cask ? .blue : .orange)
                VStack(alignment: .leading, spacing: 4) {
                    Text(package.name)
                        .font(.title2)
                        .bold()
                    Text("Active Version: \(package.version)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Done") {
                    selectedPackageForInfo = nil
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.bottom, 8)
            
            Divider()
            
            if isLoadingInfo {
                HStack {
                    Spacer()
                    ProgressView("Loading package info from Homebrew...")
                    Spacer()
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    Text(detailedInfoText)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .frame(width: 580, height: 420)
        .onAppear {
            isLoadingInfo = true
            manager.fetchPackageInfo(name: package.name) { info in
                detailedInfoText = info
                isLoadingInfo = false
            }
        }
    }
    
    // MARK: - Package Actions execution
    private func upgradePackage(_ package: BrewPackage) {
        self.isProcessing = true
        self.statusMessage = "Upgrading \(package.name)..."
        manager.upgradePackage(package) { success in
            self.isProcessing = false
            if success {
                self.statusMessage = "Successfully upgraded \(package.name)!"
            } else {
                self.statusMessage = "Failed to upgrade \(package.name). Check log traces."
            }
        }
    }
    
    private func uninstallPackage(_ package: BrewPackage) {
        let alert = NSAlert()
        alert.messageText = "Uninstall Package?"
        alert.informativeText = "Are you sure you want to uninstall \(package.name)? This will remove the package binaries from disk."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Uninstall")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            self.isProcessing = true
            self.statusMessage = "Uninstalling \(package.name)..."
            manager.uninstallPackage(package) { success in
                self.isProcessing = false
                if success {
                    self.statusMessage = "Successfully uninstalled \(package.name)!"
                } else {
                    self.statusMessage = "Failed to uninstall \(package.name)."
                }
            }
        }
    }
    
    private func pinPackage(_ package: BrewPackage) {
        manager.pinPackage(package) { success in
            if success {
                self.statusMessage = "Successfully pinned \(package.name)!"
            } else {
                self.statusMessage = "Failed to pin \(package.name)."
            }
        }
    }
    
    private func unpinPackage(_ package: BrewPackage) {
        manager.unpinPackage(package) { success in
            if success {
                self.statusMessage = "Successfully unpinned \(package.name)!"
            } else {
                self.statusMessage = "Failed to unpin \(package.name)."
            }
        }
    }
    
    private func linkPackage(_ package: BrewPackage) {
        manager.linkPackage(package) { success in
            if success {
                self.statusMessage = "Successfully linked \(package.name)!"
            } else {
                self.statusMessage = "Failed to link \(package.name)."
            }
        }
    }
    
    private func unlinkPackage(_ package: BrewPackage) {
        manager.unlinkPackage(package) { success in
            if success {
                self.statusMessage = "Successfully unlinked \(package.name)!"
            } else {
                self.statusMessage = "Failed to unlink \(package.name)."
            }
        }
    }
    
    private func runAutoremove() {
        self.isRunningAutoremove = true
        self.autoremoveOutput = "Auditing and removing orphaned dependencies..."
        manager.runAutoremove { success, log in
            self.isRunningAutoremove = false
            self.autoremoveOutput = log
            if success {
                self.statusMessage = "Autoremove completed successfully!"
            } else {
                self.statusMessage = "Autoremove encountered errors."
            }
        }
    }
    
    private func runDryRunCleanup() {
        self.isRunningDryRun = true
        self.dryRunOutput = "Scanning cache files that can be cleaned up..."
        
        guard let brew = BrewManager.brewPath else { return }
        Task.detached(priority: .userInitiated) {
            do {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: brew)
                process.arguments = ["cleanup", "-n"]
                
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = Pipe()
                
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                
                await MainActor.run {
                    self.dryRunOutput = output.isEmpty ? "No temporary caches found to reclaim." : output
                    self.isRunningDryRun = false
                }
            } catch {
                await MainActor.run {
                    self.dryRunOutput = "Error: \(error.localizedDescription)"
                    self.isRunningDryRun = false
                }
            }
        }
    }
}

// MARK: - Dependency Tree visualizer view
struct DependencyTreeView: View {
    let packageName: String
    let packages: [BrewPackage]
    let onDismiss: () -> Void
    @State private var expandedNodes: Set<String> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "arrow.triangle.merge")
                    .font(.title2)
                    .foregroundColor(.green)
                Text("Recursive Dependency Tree for \(packageName)")
                    .font(.headline)
                    .bold()
                Spacer()
                Button("Done") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    DependencyNodeView(name: packageName, depth: 0, packages: packages, expandedNodes: $expandedNodes)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.2))
            .cornerRadius(8)
        }
        .padding()
        .frame(width: 500, height: 400)
        .onAppear {
            expandedNodes.insert(packageName)
        }
    }
}

struct DependencyNodeView: View {
    let name: String
    let depth: Int
    let packages: [BrewPackage]
    @Binding var expandedNodes: Set<String>
    
    var body: some View {
        let package = packages.first(where: { $0.name == name })
        let deps = package?.dependencies ?? []
        
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Spacer().frame(width: CGFloat(depth) * 16)
                
                if !deps.isEmpty {
                    Button(action: {
                        if expandedNodes.contains(name) {
                            expandedNodes.remove(name)
                        } else {
                            expandedNodes.insert(name)
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(expandedNodes.contains(name) ? 90 : 0))
                    }
                    .buttonStyle(.plain)
                } else {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 4))
                        .foregroundColor(.secondary.opacity(0.5))
                        .frame(width: 9, height: 9)
                }
                
                Image(systemName: (package?.type == .cask) ? "macwindow" : "terminal.fill")
                    .font(.caption)
                    .foregroundColor((package?.type == .cask) ? .blue : .orange)
                
                Text(name)
                    .font(.system(.body, design: .monospaced))
                    .bold(depth == 0)
                
                if let ver = package?.version {
                    Text("v\(ver)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if expandedNodes.contains(name) {
                ForEach(deps, id: \.self) { dep in
                    DependencyNodeView(name: dep, depth: depth + 1, packages: packages, expandedNodes: $expandedNodes)
                }
            }
        }
    }
}
