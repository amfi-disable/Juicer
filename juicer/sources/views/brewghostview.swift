import SwiftUI

struct brewghostview: View {
    @StateObject private var manager = BrewGhostManager.shared
    @State private var selectedTab = 0
    @State private var showingExorciseConfirm = false
    @State private var targetExorcisePackage: String? = nil
    
    var totalReclaimableBytes: Int64 {
        manager.ghosts.reduce(0) { $0 + $1.size }
    }
    
    var formattedReclaimableSpace: String {
        ByteCountFormatter.string(fromByteCount: totalReclaimableBytes, countStyle: .file)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Banner
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 48, height: 48)
                    Image(systemName: "ghost.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Brew-Ghost Companion")
                            .font(.title2).bold()
                        
                        Text("🌟 CREATOR ORIGINAL")
                            .font(.system(size: 9, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.18), in: Capsule())
                            .foregroundColor(.purple)
                        
                        Text("TOP BREW TOOL")
                            .font(.system(size: 9, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.18), in: Capsule())
                            .foregroundColor(.orange)
                    }
                    
                    HStack(spacing: 8) {
                        Text("Automated ghost package & orphan formula cleanup utility")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Button(action: {
                            if let url = URL(string: "https://github.com/amfi-disable/Brew-Ghost") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.right.square.fill")
                                Text("amfi-disable/Brew-Ghost")
                            }
                            .font(.caption.bold())
                            .foregroundColor(.purple)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    manager.fetchGhosts()
                    manager.fetchHistory()
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
            .padding(20)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Picker tab bar
            HStack {
                Picker("", selection: $selectedTab) {
                    Text("Cellar Ghosts (\(manager.ghosts.count))").tag(0)
                    Text("Exorcism History (\(manager.historyItems.count))").tag(1)
                    Text("Settings").tag(2)
                }
                .pickerStyle(.segmented)
                .frame(width: 400)
                
                Spacer()
                
                if selectedTab == 0 && !manager.ghosts.isEmpty {
                    Text("Reclaimable: \(formattedReclaimableSpace)")
                        .font(.subheadline).bold()
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            Divider()
            
            // Main content body
            if manager.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text(manager.statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                switch selectedTab {
                case 0:
                    ghostsListView()
                case 1:
                    historyListView()
                default:
                    settingsView()
                }
            }
        }
        .onAppear {
            manager.fetchGhosts()
            manager.fetchHistory()
        }
        .alert(item: $targetExorcisePackage) { pkgName in
            Alert(
                title: Text("Exorcise Package"),
                message: Text("Are you sure you want to uninstall '\(pkgName)'? This action will remove the package from your Homebrew Cellar."),
                primaryButton: .destructive(Text("Uninstall")) {
                    manager.exorcise(package: pkgName)
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // MARK: - Ghosts List View
    @ViewBuilder
    private func ghostsListView() -> some View {
        if manager.ghosts.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                Text("Cellar is Clean!")
                    .font(.title3).bold()
                Text("No Homebrew packages detected with inactivity >= \(manager.daysThreshold) days.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(manager.ghosts) { ghost in
                    HStack(spacing: 16) {
                        Image(systemName: "shippingbox.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ghost.name)
                                .font(.headline)
                            Text("Idle for \(ghost.daysIdle) days")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        Spacer()
                        
                        Text(ghost.formattedSize)
                            .font(.callout).bold()
                            .foregroundStyle(.secondary)
                        
                        Button("Exorcise") {
                            targetExorcisePackage = ghost.name
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.inset)
        }
    }
    
    // MARK: - History List View
    @ViewBuilder
    private func historyListView() -> some View {
        if manager.historyItems.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 48))
                    .foregroundStyle(.tertiary)
                Text("No History Logs")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("Package uninstallations performed via Brew-Ghost CLI or Juicer will log here.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 0) {
                HStack {
                    Text("Recorded Exorcisms")
                        .font(.headline)
                    Spacer()
                    Button("Clear History", role: .destructive) {
                        manager.clearHistory()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                
                Divider()
                
                List {
                    ForEach(manager.historyItems) { item in
                        HStack(spacing: 16) {
                            Image(systemName: "trash.circle.fill")
                                .font(.title3)
                                .foregroundColor(.purple)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.package)
                                    .font(.headline)
                                Text("Exorcised on \(item.formattedDate)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(item.formattedSize)
                                    .font(.subheadline).bold()
                                Text("Was idle \(item.daysIdle) days")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .listStyle(.inset)
            }
        }
    }
    
    // MARK: - Settings View
    @ViewBuilder
    private func settingsView() -> some View {
        Form {
            Section("Ghost Detection Settings") {
                Picker("Inactivity Threshold:", selection: Binding(
                    get: { manager.daysThreshold },
                    set: { manager.setDaysThreshold($0) }
                )) {
                    Text("10 Days").tag(10)
                    Text("30 Days").tag(30)
                    Text("60 Days").tag(60)
                    Text("90 Days (Default)").tag(90)
                    Text("120 Days").tag(120)
                    Text("180 Days").tag(180)
                }
                .pickerStyle(.menu)
                
                Text("Packages unused for longer than this threshold will be flagged as freeloaders.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("CLI Integration Status") {
                HStack {
                    Text("brew-ghost Path:")
                    Spacer()
                    Text(BrewGhostManager.brewGhostPath ?? "Not Found")
                        .font(.footnote)
                        .foregroundColor(BrewGhostManager.brewGhostPath != nil ? .green : .red)
                }
                
                HStack {
                    Text("Config Location:")
                    Spacer()
                    Text(manager.configPath)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("History Location:")
                    Spacer()
                    Text(manager.historyPath)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }
}

extension String: Identifiable {
    public var id: String { self }
}
