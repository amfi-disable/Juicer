import SwiftUI

struct brewservicesview: View {
    @StateObject private var manager = BrewServicesManager.shared
    @State private var searchText = ""
    @State private var showingLinkManager: BrewService? = nil
    @State private var statusMessage = ""
    @State private var showStatusAlert = false
    
    // Custom Link state
    @State private var customLinkLabel = ""
    @State private var customLinkURL = ""
    
    var filteredServices: [BrewService] {
        if searchText.isEmpty {
            return manager.services
        }
        return manager.services.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header panel
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Homebrew Services Manager")
                        .font(.title2)
                        .bold()
                    Text("Manage running databases, web servers, and background daemons.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                // Domain Selector
                Picker("Domain", selection: $manager.isSystemDomain) {
                    Text("User Services").tag(false)
                    Text("System Services (Sudo)").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 320)
                .onChange(of: manager.isSystemDomain) { _ in
                    manager.loadServices()
                }
                
                if manager.isLoading {
                    ProgressView().controlSize(.small)
                } else {
                    Button(action: { manager.loadServices() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .help("Refresh Services")
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            
            Divider()
            
            // Bulk controls & Search
            HStack {
                HStack(spacing: 12) {
                    Button(action: { runBulkAction("start") }) {
                        Label("Start All", systemImage: "play.fill")
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.green)
                    
                    Button(action: { runBulkAction("stop") }) {
                        Label("Stop All", systemImage: "stop.fill")
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search service...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            
            Divider()
            
            // Services List
            if filteredServices.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "cpu.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "No Homebrew Services Found" : "No Matches Found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    if searchText.isEmpty {
                        Text("Install services via brew (e.g. redis, postgresql, nginx) to manage them here.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredServices) { service in
                            serviceRow(service)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            manager.loadServices()
        }
        .alert("Service Operation", isPresented: $showStatusAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(statusMessage)
        }
        .sheet(item: $showingLinkManager) { service in
            linkManagerSheet(service)
        }
    }
    
    // Row Builder
    @ViewBuilder
    private func serviceRow(_ service: BrewService) -> some View {
        HStack(spacing: 16) {
            // Status bulb
            Circle()
                .fill(statusColor(service.status))
                .frame(width: 10, height: 10)
                .shadow(color: statusColor(service.status).opacity(0.5), radius: 3)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(service.name)
                        .font(.headline)
                        .bold()
                    
                    // Web Interface Quick link icons
                    ForEach(service.customLinks) { link in
                        Button(action: { launchURL(link.urlString) }) {
                            Image(systemName: "safari")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        .help("Open \(link.label): \(link.urlString)")
                    }
                }
                
                HStack(spacing: 16) {
                    Text(service.status.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor(service.status).opacity(0.15))
                        .cornerRadius(4)
                    
                    if let user = service.user {
                        Text("User: \(user)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !service.ports.isEmpty {
                        Text("Ports: \(service.ports.map(String.init).joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.teal)
                            .bold()
                    }
                }
            }
            
            Spacer()
            
            // Plist Location (compact)
            if let path = service.plistPath, !path.isEmpty {
                Text(URL(fileURLWithPath: path).lastPathComponent)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: 150, alignment: .trailing)
                    .help(path)
            }
            
            // Actions
            HStack(spacing: 8) {
                if service.status == .started {
                    Button(action: { stopService(service) }) {
                        Image(systemName: "stop.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.bordered)
                    .help("Stop Service")
                    
                    Button(action: { restartService(service) }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.bordered)
                    .help("Restart Service")
                } else {
                    Button(action: { startService(service) }) {
                        Image(systemName: "play.fill")
                            .foregroundColor(.green)
                    }
                    .buttonStyle(.bordered)
                    .help("Start Service")
                }
                
                Button(action: { showingLinkManager = service }) {
                    Image(systemName: "link")
                }
                .buttonStyle(.bordered)
                .help("Manage Web Links")
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // Status colors helper
    private func statusColor(_ status: BrewService.ServiceStatus) -> Color {
        switch status {
        case .started: return .green
        case .stopped: return .gray
        case .error: return .red
        case .unknown: return .orange
        }
    }
    
    // Actions Execution
    private func startService(_ service: BrewService) {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .drawCompleted)
        manager.startService(service) { success in
            if !success {
                statusMessage = "Failed to start service \(service.name)."
                showStatusAlert = true
            }
        }
    }
    
    private func stopService(_ service: BrewService) {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .drawCompleted)
        manager.stopService(service) { success in
            if !success {
                statusMessage = "Failed to stop service \(service.name)."
                showStatusAlert = true
            }
        }
    }
    
    private func restartService(_ service: BrewService) {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .drawCompleted)
        manager.restartService(service) { success in
            if !success {
                statusMessage = "Failed to restart service \(service.name)."
                showStatusAlert = true
            }
        }
    }
    
    private func runBulkAction(_ action: String) {
        let targets = filteredServices.filter {
            action == "start" ? ($0.status != .started) : ($0.status == .started)
        }
        guard !targets.isEmpty else { return }
        
        let dispatchGroup = DispatchGroup()
        var failedCount = 0
        
        for service in targets {
            dispatchGroup.enter()
            if action == "start" {
                manager.startService(service) { success in
                    if !success { failedCount += 1 }
                    dispatchGroup.leave()
                }
            } else {
                manager.stopService(service) { success in
                    if !success { failedCount += 1 }
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if failedCount > 0 {
                statusMessage = "Bulk \(action) finished. \(failedCount) services failed to transition."
                showStatusAlert = true
            }
            manager.loadServices()
        }
    }
    
    // Link Manager Sheet
    @ViewBuilder
    private func linkManagerSheet(_ service: BrewService) -> some View {
        VStack(spacing: 20) {
            Text("Web Interface Links for \(service.name)")
                .font(.headline)
                .bold()
            
            // Add form
            VStack(alignment: .leading, spacing: 8) {
                Text("Add Custom Link").font(.subheadline).bold()
                HStack {
                    TextField("Label (e.g. Admin UI)", text: $customLinkLabel)
                        .textFieldStyle(.roundedBorder)
                    TextField("URL (e.g. http://localhost:8080)", text: $customLinkURL)
                        .textFieldStyle(.roundedBorder)
                    Button("Add") {
                        addCustomLink(for: service)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(customLinkLabel.isEmpty || customLinkURL.isEmpty)
                }
                
                // Suggestions based on ports
                if !service.ports.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Suggested Links:").font(.caption).foregroundColor(.secondary)
                        HStack {
                            ForEach(service.ports, id: \.self) { port in
                                Button("localhost:\(port)") {
                                    customLinkLabel = "Port \(port)"
                                    customLinkURL = "http://localhost:\(port)"
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.4))
            .cornerRadius(8)
            
            // Existing links list
            List {
                if service.customLinks.isEmpty {
                    Text("No custom links configured.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(service.customLinks) { link in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(link.label).bold()
                                Text(link.urlString).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Remove", role: .destructive) {
                                removeCustomLink(link, for: service)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .frame(height: 180)
            
            HStack {
                Spacer()
                Button("Done") {
                    customLinkLabel = ""
                    customLinkURL = ""
                    showingLinkManager = nil
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 500, height: 420)
    }
    
    private func addCustomLink(for service: BrewService) {
        var currentLinks = service.customLinks
        let newLink = ServiceLink(label: customLinkLabel, urlString: customLinkURL)
        currentLinks.append(newLink)
        manager.saveCustomLinks(for: service.name, links: currentLinks)
        customLinkLabel = ""
        customLinkURL = ""
        // Update temporary sheet state
        if let idx = manager.services.firstIndex(where: { $0.id == service.id }) {
            showingLinkManager = manager.services[idx]
        }
    }
    
    private func removeCustomLink(_ link: ServiceLink, for service: BrewService) {
        let updated = service.customLinks.filter { $0.id != link.id }
        manager.saveCustomLinks(for: service.name, links: updated)
        if let idx = manager.services.firstIndex(where: { $0.id == service.id }) {
            showingLinkManager = manager.services[idx]
        }
    }
    
    private func launchURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}
