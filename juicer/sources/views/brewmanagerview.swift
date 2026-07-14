import SwiftUI

struct brewmanagerview: View {
    @StateObject private var manager = BrewManager()
    @State private var searchText = ""
    @State private var selectedTab = 0 // 0: Formulae, 1: Casks, 2: Outdated, 3: Diagnostics
    @State private var isProcessing = false
    @State private var statusMessage = ""
    
    @State private var selectedPackageForInfo: BrewPackage?
    @State private var detailedInfoText = ""
    @State private var isLoadingInfo = false
    
    var filteredPackages: [BrewPackage] {
        let list: [BrewPackage]
        switch selectedTab {
        case 0:
            list = manager.packages.filter { $0.type == .formula }
        case 1:
            list = manager.packages.filter { $0.type == .cask }
        case 2:
            list = manager.packages.filter { $0.isOutdated }
        default:
            list = []
        }
        
        if searchText.isEmpty {
            return list
        } else {
            return list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
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
                // Header & Stats
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Homebrew Package Manager")
                            .font(.title2)
                            .bold()
                        Text("Manage packages, update outdated casks/formulae, and run diagnostics.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    if manager.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Button(action: { manager.loadPackages() }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                        .help("Refresh Packages List")
                    }
                }
                .padding()
                .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
                
                Divider()
                
                // Toolbar & Search
                HStack(spacing: 12) {
                    Picker("", selection: $selectedTab) {
                        Text("Formulae (\(manager.packages.filter { $0.type == .formula }.count))").tag(0)
                        Text("Casks (\(manager.packages.filter { $0.type == .cask }.count))").tag(1)
                        Text("Outdated (\(manager.packages.filter { $0.isOutdated }.count))").tag(2)
                        Text("Diagnostics").tag(3)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 440)
                    
                    if selectedTab != 3 {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search package...", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 180)
                    }
                }
                .padding()
                
                Divider()
                
                // Content
                if selectedTab == 3 {
                    diagnosticsTab()
                } else {
                    packagesList()
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
    }
    
    // MARK: - Packages List View
    @ViewBuilder
    private func packagesList() -> some View {
        if manager.isLoading {
            VStack {
                ProgressView("Scanning installed packages...")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if filteredPackages.isEmpty {
            VStack {
                Image(systemName: "shippingbox")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
                Text(searchText.isEmpty ? "No packages found in this category." : "No search results found.")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(filteredPackages) { package in
                HStack(spacing: 16) {
                    // Package icon decoration
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(package.type == .cask ? Color.blue.opacity(0.15) : Color.orange.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: package.type == .cask ? "macwindow" : "terminal.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(package.type == .cask ? Color.blue : Color.orange)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(package.name)
                                .font(.headline)
                            
                            Button(action: {
                                self.selectedPackageForInfo = package
                            }) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.plain)
                            .help("View Package Details")
                        }
                        
                        HStack(spacing: 6) {
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
                    
                    // Action controls
                    HStack(spacing: 8) {
                        if package.isOutdated {
                            Button("Upgrade") {
                                upgradePackage(package)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .disabled(isProcessing)
                        }
                        
                        Button("Uninstall") {
                            uninstallPackage(package)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isProcessing)
                    }
                }
                .padding(.vertical, 4)
                Divider()
            }
            .listStyle(.plain)
        }
    }
    
    // MARK: - Diagnostics Tab View
    @ViewBuilder
    private func diagnosticsTab() -> some View {
        HStack(spacing: 20) {
            // Brew Doctor Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "stethoscope")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text("Brew Doctor")
                        .font(.headline)
                    Spacer()
                    if manager.isRunningDoctor {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Button("Run Doctor") {
                            manager.runDoctor()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                ScrollView {
                    Text(manager.doctorOutput.isEmpty ? "Check your Homebrew configuration health." : manager.doctorOutput)
                        .font(.system(.body, design: .monospaced))
                        .padding(10)
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
            
            // Brew Cleanup Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "broom.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text("Orphan Cleanup")
                        .font(.headline)
                    Spacer()
                    if manager.isRunningCleanup {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Button("Run Cleanup") {
                            manager.runCleanup()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                ScrollView {
                    Text(manager.cleanupOutput.isEmpty ? "Remove old lockfiles, unused packages downloads cache, and free up space." : manager.cleanupOutput)
                        .font(.system(.body, design: .monospaced))
                        .padding(10)
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
    
    // MARK: - Actions
    private func upgradePackage(_ package: BrewPackage) {
        self.isProcessing = true
        self.statusMessage = "Upgrading \(package.name)..."
        
        manager.upgradePackage(package) { success in
            self.isProcessing = false
            if success {
                self.statusMessage = "Successfully upgraded \(package.name)!"
            } else {
                self.statusMessage = "Failed to upgrade \(package.name). Check logger."
            }
        }
    }
    
    private func uninstallPackage(_ package: BrewPackage) {
        let alert = NSAlert()
        alert.messageText = "Uninstall Package?"
        alert.informativeText = "Are you sure you want to uninstall \(package.name)? This cannot be undone."
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
                    self.statusMessage = "Failed to uninstall \(package.name). Check logger."
                }
            }
        }
    }
}
