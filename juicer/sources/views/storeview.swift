import SwiftUI

enum StoreFilterType: String, CaseIterable, Identifiable {
    case all = "All Apps"
    case installed = "Installed"
    case updates = "Updates"
    
    var id: String { rawValue }
}

struct storeview: View {
    let isCask: Bool
    let filterType: StoreFilterType
    
    init(isCask: Bool = true, filterType: StoreFilterType = .all) {
        self.isCask = isCask
        self.filterType = filterType
    }
    
    @StateObject private var manager = StoreManager()
    @State private var searchText = ""
    @State private var selectedCategory: AppCategory? = nil
    @State private var selectedPricing: StoreApp.PricingTag? = nil
    
    // Pagination
    @State private var currentPage = 1
    private let itemsPerPage = 30
    
    // Selection for Detail Sheet
    @State private var selectedApp: StoreApp? = nil
    @State private var showLogs = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Controls: Search and Filters
            filterHeader()
            
            if manager.isLoading {
                loadingPlaceholder()
            } else if filteredApps.isEmpty {
                emptyStatePlaceholder()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // 1. Featured Section (Only for "All" view on Page 1)
                        if filterType == .all && searchText.isEmpty && selectedCategory == nil && selectedPricing == nil && currentPage == 1 {
                            featuredHeroSection()
                                .padding(.horizontal)
                                .padding(.top)
                        }
                        
                        // 2. Apps List / Grid
                        appsGridView()
                            .padding(.horizontal)
                        
                        // 3. Pagination Controls
                        paginationControls()
                            .padding()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(item: $selectedApp) { app in
            appDetailSheet(app: app)
        }
        .onAppear {
            manager.loadStore()
        }
    }
    
    // MARK: - Filtering Logic
    private var filteredApps: [StoreApp] {
        var list: [StoreApp] = []
        
        switch filterType {
        case .all:
            list = manager.apps.filter { $0.isCask == isCask }
        case .installed:
            list = manager.apps.filter { $0.isCask == isCask && $0.status != .notInstalled }
        case .updates:
            list = manager.outdatedApps.filter { $0.isCask == isCask }
        }
        
        // Search filter
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            list = list.filter { $0.name.lowercased().contains(q) || $0.id.lowercased().contains(q) || $0.desc.lowercased().contains(q) }
        }
        
        // Category filter
        if let category = selectedCategory {
            list = list.filter { $0.category == category }
        }
        
        // Pricing filter
        if let pricing = selectedPricing {
            list = list.filter { $0.pricing == pricing }
        }
        
        return list
    }
    
    private var paginatedApps: [StoreApp] {
        let allFiltered = filteredApps
        let startIndex = (currentPage - 1) * itemsPerPage
        guard startIndex < allFiltered.count else { return [] }
        let endIndex = min(startIndex + itemsPerPage, allFiltered.count)
        return Array(allFiltered[startIndex..<endIndex])
    }
    
    private var totalPages: Int {
        let count = filteredApps.count
        if count == 0 { return 1 }
        return Int(ceil(Double(count) / Double(itemsPerPage)))
    }
    
    // MARK: - Filters Header
    @ViewBuilder
    private func filterHeader() -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Search Field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search by name, description, or id...", text: $searchText)
                        .textFieldStyle(.plain)
                        .onChange(of: searchText) { _ in
                            currentPage = 1
                        }
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(8)
                .frame(maxWidth: 320)
                
                // Pricing Tags Filter
                Picker("Pricing:", selection: Binding(
                    get: { selectedPricing },
                    set: { val in
                        selectedPricing = val
                        currentPage = 1
                    }
                )) {
                    Text("All pricing").tag(StoreApp.PricingTag?.none)
                    ForEach(StoreApp.PricingTag.allCases, id: \.self) { pricing in
                        Text(pricing.rawValue).tag(StoreApp.PricingTag?.some(pricing))
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 280)
                
                Spacer()
                
                // Reload Button
                Button(action: { manager.loadStore(forceRefresh: true) }) {
                    Label("Sync Database", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }
            .padding([.horizontal, .top])
            
            // Categories Selector Row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    categoryTabButton(title: "All Categories", category: nil)
                    
                    ForEach(AppCategory.allCases) { cat in
                        categoryTabButton(title: cat.rawValue, category: cat)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            Divider()
        }
        .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
    }
    
    @ViewBuilder
    private func categoryTabButton(title: String, category: AppCategory?) -> some View {
        Button(action: {
            selectedCategory = category
            currentPage = 1
        }) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedCategory == category ? Color.accentColor : Color(NSColor.controlBackgroundColor).opacity(0.4))
                .foregroundColor(selectedCategory == category ? .white : .primary)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Featured App Hero Banner
    @ViewBuilder
    private func featuredHeroSection() -> some View {
        let featured = filteredApps.filter { $0.isFeatured }
        if !featured.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Featured Applications")
                    .font(.title2).bold()
                    .foregroundColor(.primary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(featured.prefix(4)) { app in
                            featuredCard(app: app)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func featuredCard(app: StoreApp) -> some View {
        Button(action: { selectedApp = app }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: app.category.iconName)
                        .font(.title)
                        .foregroundColor(.accentColor)
                        .frame(width: 48, height: 48)
                        .background(Color.accentColor.opacity(0.12))
                        .cornerRadius(10)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.name)
                            .font(.headline)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        Text(app.category.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Pricing Badge
                    Text(app.pricing.rawValue)
                        .font(.caption2).bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(app.pricing == .free ? Color.green.opacity(0.15) : (app.pricing == .freemium ? Color.orange.opacity(0.15) : Color.blue.opacity(0.15)))
                        .foregroundColor(app.pricing == .free ? .green : (app.pricing == .freemium ? .orange : .blue))
                        .cornerRadius(6)
                }
                
                Text(app.desc)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(height: 36, alignment: .topLeading)
                
                HStack {
                    Text("Version \(app.version)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(app.status == .notInstalled ? "Get" : "Installed")
                        .font(.caption2).bold()
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(app.status == .notInstalled ? Color.accentColor : Color.secondary.opacity(0.2))
                        .foregroundColor(app.status == .notInstalled ? .white : .primary)
                        .cornerRadius(10)
                }
            }
            .padding(16)
            .frame(width: 280)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.secondary.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Apps Grid View
    @ViewBuilder
    private func appsGridView() -> some View {
        let columns = [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]
        
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(paginatedApps) { app in
                appRowCard(app: app)
            }
        }
    }
    
    @ViewBuilder
    private func appRowCard(app: StoreApp) -> some View {
        Button(action: { selectedApp = app }) {
            HStack(spacing: 12) {
                Image(systemName: app.category.iconName)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 42, height: 42)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(app.name)
                            .font(.body).bold()
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        
                        if app.isFeatured {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Text(app.desc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(app.pricing.rawValue)
                        .font(.system(size: 9)).bold()
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(app.pricing == .free ? Color.green.opacity(0.12) : (app.pricing == .freemium ? Color.orange.opacity(0.12) : Color.blue.opacity(0.12)))
                        .foregroundColor(app.pricing == .free ? .green : (app.pricing == .freemium ? .orange : .blue))
                        .cornerRadius(4)
                    
                    Text(app.status == .notInstalled ? "Get" : (app.status == .installedViaHomebrew ? "Installed" : "External"))
                        .font(.system(size: 9)).bold()
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(app.status == .notInstalled ? Color.accentColor : Color.secondary.opacity(0.2))
                        .foregroundColor(app.status == .notInstalled ? .white : .primary)
                        .cornerRadius(4)
                }
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.08), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Pagination Footer
    @ViewBuilder
    private func paginationControls() -> some View {
        HStack {
            Text("Showing \((currentPage - 1) * itemsPerPage + 1) - \(min(currentPage * itemsPerPage, filteredApps.count)) of \(filteredApps.count) apps")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {
                    if currentPage > 1 { currentPage -= 1 }
                }) {
                    Image(systemName: "chevron.left")
                }
                .disabled(currentPage == 1)
                
                Text("Page \(currentPage) of \(totalPages)")
                    .font(.subheadline)
                
                Button(action: {
                    if currentPage < totalPages { currentPage += 1 }
                }) {
                    Image(systemName: "chevron.right")
                }
                .disabled(currentPage == totalPages)
            }
        }
    }
    
    // MARK: - Loading / Empty Views
    @ViewBuilder
    private func loadingPlaceholder() -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
            Text("Updating package definitions catalog...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func emptyStatePlaceholder() -> some View {
        VStack(spacing: 12) {
            Image(systemName: "square.grid.3x3.square.badge.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No Matching Apps Found")
                .font(.headline)
            Text("Try tweaking your filters or search keywords.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - App Detail Sheet
    @ViewBuilder
    private func appDetailSheet(app: StoreApp) -> some View {
        VStack(spacing: 0) {
            // Sheet Header
            HStack {
                Image(systemName: app.category.iconName)
                    .font(.largeTitle)
                    .foregroundColor(.accentColor)
                    .frame(width: 60, height: 60)
                    .background(Color.accentColor.opacity(0.12))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name)
                        .font(.title2).bold()
                    Text("Token Identifier: \(app.id)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Close") {
                    selectedApp = nil
                }
                .buttonStyle(.bordered)
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Metadata tags
                    HStack(spacing: 16) {
                        detailTag(title: "Category", value: app.category.rawValue, icon: app.category.iconName)
                        detailTag(title: "Pricing", value: app.pricing.rawValue, icon: "dollarsign.circle")
                        detailTag(title: "Status", value: app.status.rawValue, icon: "checkmark.circle")
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        Text(app.desc.isEmpty ? "No description provided." : app.desc)
                            .foregroundColor(.secondary)
                    }
                    
                    if !app.homepage.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Links")
                                .font(.headline)
                            if let targetURL = URL(string: app.homepage) {
                                Link(destination: targetURL) {
                                    HStack {
                                        Image(systemName: "link")
                                        Text("Visit Official Homepage")
                                    }
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Action triggers
                    HStack(spacing: 12) {
                        if app.status == .notInstalled {
                            Button(action: {
                                manager.runAction(action: "install", app: app)
                                showLogs = true
                            }) {
                                Label("Install Application", systemImage: "square.and.arrow.down")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(manager.isRunningAction)
                        } else {
                            Button(action: {
                                manager.runAction(action: "uninstall", app: app)
                                showLogs = true
                            }) {
                                Label("Uninstall Application", systemImage: "trash")
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            .disabled(manager.isRunningAction)
                        }
                        
                        // Updates tab upgrade
                        if filterType == .updates {
                            Button(action: {
                                manager.runAction(action: "upgrade", app: app)
                                showLogs = true
                            }) {
                                Label("Upgrade to Latest", systemImage: "arrow.up.circle")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .disabled(manager.isRunningAction)
                        }
                    }
                    
                    // Console logs output
                    if showLogs || manager.isRunningAction {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Homebrew Operations Console")
                                .font(.headline)
                            
                            ScrollView {
                                Text(manager.progressLog)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.green)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(8)
                            }
                            .frame(height: 150)
                            .background(Color.black)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 550, height: 480)
    }
    
    @ViewBuilder
    private func detailTag(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.caption).bold()
            }
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .cornerRadius(6)
    }
}
