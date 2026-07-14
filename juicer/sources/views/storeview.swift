import SwiftUI

struct storeview: View {
    @StateObject private var manager = StoreManager()
    @State private var searchText: String = ""
    @State private var selectedApp: StoreApp? = nil
    @State private var selectedTab: StoreTab = .casks

    enum StoreTab: String, CaseIterable, Identifiable {
        case casks = "Applications"
        case formulae = "Command Line"
        case updates = "Updates"
        
        var id: String { rawValue }
    }

    // Sidebar Filters
    @State private var selectedStatus: StatusFilter = .all
    @State private var selectedPricing: PricingFilter = .all

    enum StatusFilter: String, CaseIterable, Identifiable {
        case all = "All Packages"
        case installed = "Installed"
        case notInstalled = "Not Installed"
        case external = "Installed outside Homebrew"

        var id: String { rawValue }
    }

    enum PricingFilter: String, CaseIterable, Identifiable {
        case all = "All Pricing"
        case free = "Free"
        case freemium = "Freemium"
        case paid = "Paid"

        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection()
            Divider()

            HSplitView {
                // Left side: Filters + Search + List
                VStack(spacing: 0) {
                    filterBar()
                    Divider()
                    appListView()
                }
                .frame(minWidth: 400, idealWidth: 450)

                // Right side: Detail Inspector panel
                VStack(spacing: 0) {
                    if let app = selectedApp {
                        detailPanel(app: app)
                    } else {
                        emptyDetailPlaceholder()
                    }
                }
                .frame(minWidth: 300, maxWidth: .infinity)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
            }

            // Bottom terminal output drawer if active
            if manager.isRunningAction || !manager.progressLog.isEmpty {
                terminalDrawer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            if manager.apps.isEmpty {
                manager.loadStore()
            }
        }
    }

    // MARK: - Header
    @ViewBuilder
    private func headerSection() -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Software Center")
                    .font(.title2).bold()
                Text("Discover, install, and manage applications and tools powered by Homebrew.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()

            Picker("", selection: $selectedTab) {
                Text("Applications (Casks)").tag(StoreTab.casks)
                Text("Command Line (Formulae)").tag(StoreTab.formulae)
                let updatesText = manager.outdatedApps.isEmpty ? "Updates" : "Updates (\(manager.outdatedApps.count))"
                Text(updatesText).tag(StoreTab.updates)
            }
            .pickerStyle(.segmented)
            .frame(width: 440)
            .disabled(manager.isLoading)

            Button(action: { manager.loadStore(forceRefresh: true) }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .disabled(manager.isLoading)
            .help("Force refresh package list")
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }

    // MARK: - Filters
    @ViewBuilder
    private func filterBar() -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search packages…", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.body)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)

            HStack(spacing: 8) {
                Picker("Status", selection: $selectedStatus) {
                    ForEach(StatusFilter.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)

                Picker("Pricing", selection: $selectedPricing) {
                    ForEach(PricingFilter.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.15))
    }

    // MARK: - App List
    @ViewBuilder
    private func appListView() -> some View {
        if manager.isLoading {
            VStack(spacing: 12) {
                ProgressView().controlSize(.large)
                Text("Fetching package repository from Homebrew…")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            let sourceApps = selectedTab == .updates ? manager.outdatedApps : manager.apps
            let filtered = sourceApps.filter { app in
                // Tab filter
                if selectedTab == .casks && !app.isCask { return false }
                if selectedTab == .formulae && app.isCask { return false }

                // Search query
                if !searchText.isEmpty {
                    let term = searchText.lowercased()
                    if !app.id.lowercased().contains(term) && !app.name.lowercased().contains(term) && !app.desc.lowercased().contains(term) {
                        return false
                    }
                }

                // Status filter
                switch selectedStatus {
                case .all: break
                case .installed:
                    if app.status != .installedViaHomebrew && app.status != .installedExternally { return false }
                case .notInstalled:
                    if app.status != .notInstalled { return false }
                case .external:
                    if app.status != .installedExternally { return false }
                }

                // Pricing filter
                switch selectedPricing {
                case .all: break
                case .free:
                    if app.pricing != .free { return false }
                case .freemium:
                    if app.pricing != .freemium { return false }
                case .paid:
                    if app.pricing != .paid { return false }
                }

                return true
            }

            if filtered.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "square.grid.3x3.fill").font(.system(size: 36)).foregroundStyle(.secondary)
                    Text("No matching packages found")
                        .font(.headline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selectedApp) {
                    ForEach(filtered) { app in
                        appRow(app: app)
                            .tag(app)
                    }
                }
                .listStyle(.inset)
            }
        }
    }

    @ViewBuilder
    private func appRow(app: StoreApp) -> some View {
        HStack(spacing: 12) {
            faviconImage(homepage: app.homepage, isCask: app.isCask)
                .frame(width: 32, height: 32)
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(app.name).font(.headline).lineLimit(1)
                    pricingBadge(app.pricing)
                    if app.status == .installedViaHomebrew || app.status == .installedExternally {
                        statusBadge(app.status)
                    }
                }
                Text(app.desc.isEmpty ? "No description available" : app.desc)
                    .font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                Text(app.id)
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Detail Panel
    @ViewBuilder
    private func detailPanel(app: StoreApp) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 16) {
                    faviconImage(homepage: app.homepage, isCask: app.isCask, size: 64)
                        .frame(width: 64, height: 64)
                        .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(app.name).font(.title3).bold()
                        Text(app.id).font(.subheadline).foregroundStyle(.secondary)
                        HStack(spacing: 6) {
                            pricingBadge(app.pricing)
                            statusBadge(app.status)
                        }
                    }
                    Spacer()
                }

                Divider()

                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description").font(.headline)
                    Text(app.desc.isEmpty ? "No description available." : app.desc)
                        .font(.body).foregroundStyle(.secondary)
                }

                // Metadata rows
                VStack(alignment: .leading, spacing: 10) {
                    metadataRow(label: "Version", value: app.version.isEmpty ? "unknown" : app.version)
                    metadataRow(label: "Type", value: app.isCask ? "Application (.app)" : "CLI command / library")
                    if !app.homepage.isEmpty {
                        HStack {
                            Text("Website").font(.caption).bold().foregroundStyle(.secondary).frame(width: 90, alignment: .leading)
                            Link(app.homepage, destination: URL(string: app.homepage) ?? URL(string: "https://brew.sh")!)
                                .font(.caption).lineLimit(1)
                        }
                    }
                    if app.isCask && !app.appNames.isEmpty {
                        metadataRow(label: "App Names", value: app.appNames.joined(separator: ", "))
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(8)

                // Actions warning if externally installed
                if app.status == .installedExternally {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Installed Outside Homebrew").bold().font(.subheadline)
                            Text("This application was installed manually or through another installer. Homebrew cannot directly manage or update it unless you override it.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(8)
                }

                // Action buttons
                VStack(spacing: 10) {
                    if app.status == .notInstalled {
                        Button(action: { manager.runAction(action: "install", app: app) }) {
                            HStack {
                                Image(systemName: "arrow.down.to.line.compact")
                                Text("Install Package")
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(manager.isRunningAction)
                    } else if app.status == .installedViaHomebrew {
                        if selectedTab == .updates {
                            Button(action: { manager.runAction(action: "upgrade", app: app) }) {
                                HStack {
                                    Image(systemName: "arrow.up.circle.fill")
                                    Text("Upgrade Package")
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 6)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(manager.isRunningAction)
                        } else {
                            Button(action: { manager.runAction(action: "uninstall", app: app) }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                    Text("Uninstall Package")
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 6)
                            }
                            .buttonStyle(.borderedProminent).tint(.red)
                            .disabled(manager.isRunningAction)
                        }
                    } else if app.status == .installedExternally {
                        Button(action: { manager.runAction(action: "install", app: app) }) {
                            HStack {
                                Image(systemName: "arrow.down.to.line.compact")
                                Text("Override & Install via Brew")
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 6)
                        }
                        .buttonStyle(.bordered)
                        .disabled(manager.isRunningAction)

                        Text("Or clean leftover configuration files using standard uninstallation:")
                            .font(.caption2).foregroundStyle(.tertiary).multilineTextAlignment(.center)

                        Button("Open App Uninstaller") {
                            // Send notification to switch to App Uninstaller view
                            NotificationCenter.default.post(name: NSNotification.Name("juicer.nav.uninstaller"), object: nil)
                        }
                        .buttonStyle(.link)
                    }
                }
                .padding(.top, 10)
            }
            .padding()
        }
    }

    @ViewBuilder
    private func emptyDetailPlaceholder() -> some View {
        VStack(spacing: 12) {
            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 48)).foregroundStyle(.secondary)
            Text("No Package Selected")
                .font(.headline).foregroundStyle(.secondary)
            Text("Select an application or CLI package to inspect detail properties and trigger installation actions.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Terminal Progress Log Drawer
    @ViewBuilder
    private func terminalDrawer() -> some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Text("Homebrew Action Console Output")
                    .font(.caption).bold().foregroundStyle(.secondary)
                Spacer()
                if manager.isRunningAction {
                    ProgressView().controlSize(.small).scaleEffect(0.8)
                    Button("Cancel") { manager.cancelAction() }
                        .buttonStyle(.bordered).controlSize(.small)
                } else {
                    Button("Clear Console") { manager.progressLog = "" }
                        .buttonStyle(.bordered).controlSize(.small)
                }
            }
            .padding(.horizontal).padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    Text(manager.progressLog)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .id("bottom")
                }
                .frame(height: 140)
                .background(Color(NSColor.controlBackgroundColor))
                .onChange(of: manager.progressLog) { _ in
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func faviconImage(homepage: String, isCask: Bool, size: CGFloat = 32) -> some View {
        if let host = homepageHost(homepage), !host.isEmpty {
            AsyncImage(url: URL(string: "https://www.google.com/s2/favicons?sz=64&domain=\(host)")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                default:
                    Image(systemName: isCask ? "macwindow" : "terminal.fill")
                        .font(.system(size: size * 0.5))
                        .foregroundColor(.secondary)
                }
            }
        } else {
            Image(systemName: isCask ? "macwindow" : "terminal.fill")
                .font(.system(size: size * 0.5))
                .foregroundColor(.secondary)
        }
    }

    private func homepageHost(_ urlStr: String) -> String? {
        guard let url = URL(string: urlStr) else { return nil }
        return url.host
    }

    private func pricingColor(_ pricing: StoreApp.PricingTag) -> Color {
        switch pricing {
        case .free: return .green
        case .freemium: return .orange
        case .paid: return .blue
        }
    }

    @ViewBuilder
    private func pricingBadge(_ pricing: StoreApp.PricingTag) -> some View {
        let color = pricingColor(pricing)
        Text(pricing.rawValue)
            .font(.caption2).bold()
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .cornerRadius(4)
    }

    @ViewBuilder
    private func statusBadge(_ status: StoreApp.InstallationStatus) -> some View {
        switch status {
        case .installedViaHomebrew:
            Text("Brew Installed")
                .font(.caption2).bold()
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Color.green.opacity(0.12))
                .foregroundStyle(Color.green)
                .cornerRadius(4)
        case .installedExternally:
            Text("Installed Outside Homebrew")
                .font(.caption2).bold()
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Color.orange.opacity(0.12))
                .foregroundStyle(Color.orange)
                .cornerRadius(4)
        case .notInstalled:
            EmptyView()
        }
    }

    @ViewBuilder
    private func metadataRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).font(.caption).bold().foregroundStyle(.secondary).frame(width: 90, alignment: .leading)
            Text(value).font(.caption).foregroundStyle(.primary)
            Spacer()
        }
    }
}
