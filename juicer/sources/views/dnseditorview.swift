import SwiftUI

struct dnseditorview: View {
    @StateObject private var manager = DNSManager()
    
    // New Record input fields
    @State private var newIP = "127.0.0.1"
    @State private var newDomain = ""
    @State private var showValidationError = false
    @State private var validationErrorMessage = ""
    
    // Create Profile sheets
    @State private var showCreateProfile = false
    @State private var newProfileName = ""
    @State private var newProfileDesc = ""
    @State private var newProfileSubURL = ""
    
    var body: some View {
        HStack(spacing: 0) {
            // LEFT SIDEBAR: DNS Profiles List
            profilesSidebar()
                .frame(width: 240)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
            
            Divider()
            
            // RIGHT DETAIL: Records and Actions list
            VStack(spacing: 0) {
                headerSection()
                Divider()
                
                if let activeId = manager.activeProfileId,
                   let profile = manager.profiles.first(where: { $0.id == activeId }) {
                    
                    // Show subscription alert banner if it's a remote subscription
                    if let subURL = profile.subscriptionURL, !subURL.isEmpty {
                        subscriptionBanner(profile: profile, url: subURL)
                    } else {
                        addEntryForm()
                            .padding()
                    }
                    
                    // Records details
                    if manager.isLoading || manager.isDownloading {
                        loadingPlaceholder()
                    } else if manager.records.isEmpty {
                        emptyStatePlaceholder()
                    } else {
                        recordsList()
                    }
                } else {
                    noProfileSelectedPlaceholder()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showCreateProfile) {
            createProfileSheet()
        }
    }
    
    // MARK: - Sidebar UI
    @ViewBuilder
    private func profilesSidebar() -> some View {
        VStack(spacing: 0) {
            // Sidebar Header
            HStack {
                Text("DNS Profiles")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { showCreateProfile = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .help("Create New Profile")
            }
            .padding()
            
            Divider()
            
            // Profiles List
            List(manager.profiles) { profile in
                Button(action: { manager.selectProfile(profileId: profile.id) }) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(profile.name)
                                .font(.body)
                                .bold(manager.activeProfileId == profile.id)
                                .foregroundColor(manager.activeProfileId == profile.id ? .accentColor : .primary)
                            Spacer()
                            if profile.subscriptionURL != nil {
                                Image(systemName: "icloud.and.arrow.down.fill")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text(profile.description)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(manager.activeProfileId == profile.id ? Color.accentColor.opacity(0.12) : Color.clear)
                .cornerRadius(8)
                // Add Delete Profile swipe/context actions
                .contextMenu {
                    if profile.name != "System Default" && profile.name != "Ad Blocker (StevenBlack)" && profile.name != "Developer Workspace" {
                        Button("Delete Profile", role: .destructive) {
                            manager.deleteProfile(profileId: profile.id)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            
            Spacer()
        }
    }
    
    // MARK: - Subscription Banner UI
    @ViewBuilder
    private func subscriptionBanner(profile: DNSProfile, url: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hosts Subscription Active")
                        .font(.subheadline).bold()
                    Text("Domain listings are fetched from remote subscription lists.")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Button(action: { manager.downloadSubscription(profile: profile) }) {
                    HStack {
                        Image(systemName: "arrow.clockwise.icloud.fill")
                        Text("Update List")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(manager.isDownloading)
            }
            Text("URL: \(url)")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding()
        .background(Color.blue.opacity(0.08))
        .cornerRadius(8)
        .padding()
    }
    
    // MARK: - Header UI
    @ViewBuilder
    private func headerSection() -> some View {
        HStack {
            if let activeId = manager.activeProfileId,
               let profile = manager.profiles.first(where: { $0.id == activeId }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .font(.title2)
                        .bold()
                    Text(profile.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("DNS Editor")
                    .font(.title2)
                    .bold()
            }
            
            Spacer()
            
            Button(action: { manager.loadHosts() }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Reload")
                }
            }
            .buttonStyle(.bordered)
            .disabled(manager.isLoading || manager.isSaving || manager.isDownloading)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }
    
    // MARK: - Add Entry Form UI
    @ViewBuilder
    private func addEntryForm() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                TextField("IP Address (e.g. 127.0.0.1)", text: $newIP)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                
                TextField("Hostname (e.g. local.dev)", text: $newDomain)
                    .textFieldStyle(.roundedBorder)
                
                Button(action: addRecord) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Mapping")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newIP.isEmpty || newDomain.isEmpty)
            }
            
            if showValidationError {
                Text(validationErrorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Loading Indicator
    @ViewBuilder
    private func loadingPlaceholder() -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
            Text(manager.isDownloading ? "Downloading remote lists..." : "Reading hosts configuration...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Placeholders
    @ViewBuilder
    private func emptyStatePlaceholder() -> some View {
        VStack {
            Spacer()
            Image(systemName: "network")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.6))
            Text("No Host Records Found")
                .font(.headline)
                .padding(.top, 8)
            Text("This profile is empty. Add a mapping above to get started!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func noProfileSelectedPlaceholder() -> some View {
        VStack {
            Spacer()
            Image(systemName: "network.badge.shield.half.filled")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.6))
            Text("No Active DNS Profile")
                .font(.headline)
                .padding(.top, 8)
            Text("Select or create a DNS profile in the sidebar to start.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Records List UI
    @ViewBuilder
    private func recordsList() -> some View {
        VStack(spacing: 0) {
            List {
                Section(header: listHeader()) {
                    ForEach(manager.records) { record in
                        recordRow(record: record)
                    }
                }
            }
            .listStyle(.inset)
            
            // Bottom Operations Bar
            HStack {
                Text("System mappings are protected and cannot be disabled. Click Apply to overwrite /etc/hosts.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button(action: saveChanges) {
                    if manager.isSaving {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.5)
                    } else {
                        Text("Apply & Save DNS Profiles")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .disabled(manager.isSaving)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
        }
    }
    
    @ViewBuilder
    private func listHeader() -> some View {
        HStack {
            Text("")
                .frame(width: 30)
            Text("IP Address")
                .bold()
                .frame(width: 150, alignment: .leading)
            Text("Hostname")
                .bold()
            Spacer()
            Text("Source")
                .bold()
                .frame(width: 100, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func recordRow(record: HostRecord) -> some View {
        HStack {
            // Toggle mapping checkbox (disabled for system items)
            Toggle("", isOn: Binding(
                get: { record.isEnabled },
                set: { value in
                    if let index = manager.records.firstIndex(where: { $0.id == record.id }) {
                        manager.records[index].isEnabled = value
                    }
                }
            ))
            .toggleStyle(.checkbox)
            .disabled(record.isSystem)
            .frame(width: 30)
            
            Text(record.ip)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(record.isEnabled ? .primary : .secondary)
                .strikethrough(!record.isEnabled)
                .frame(width: 150, alignment: .leading)
            
            Text(record.domain)
                .font(.body)
                .foregroundColor(record.isEnabled ? .primary : .secondary)
                .strikethrough(!record.isEnabled)
            
            Spacer()
            
            Text(record.isSystem ? "System" : "User")
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(record.isSystem ? Color.blue.opacity(0.15) : Color.orange.opacity(0.15))
                .foregroundColor(record.isSystem ? .blue : .orange)
                .cornerRadius(4)
                .frame(width: 100, alignment: .trailing)
        }
        .padding(.vertical, 2)
    }
    
    // MARK: - Create Profile Sheet
    @ViewBuilder
    private func createProfileSheet() -> some View {
        VStack(spacing: 16) {
            Text("Create DNS Profile")
                .font(.headline)
            
            Form {
                TextField("Profile Name", text: $newProfileName)
                TextField("Description", text: $newProfileDesc)
                TextField("Subscription URL (Optional)", text: $newProfileSubURL)
            }
            .textFieldStyle(.roundedBorder)
            
            HStack {
                Button("Cancel") {
                    showCreateProfile = false
                    clearProfileSheetFields()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Create") {
                    let subURL = newProfileSubURL.trimmingCharacters(in: .whitespacesAndNewlines)
                    manager.createProfile(
                        name: newProfileName,
                        description: newProfileDesc,
                        subscriptionURL: subURL.isEmpty ? nil : subURL
                    )
                    showCreateProfile = false
                    clearProfileSheetFields()
                }
                .buttonStyle(.borderedProminent)
                .disabled(newProfileName.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 220)
    }
    
    private func clearProfileSheetFields() {
        newProfileName = ""
        newProfileDesc = ""
        newProfileSubURL = ""
    }
    
    // MARK: - Actions
    private func addRecord() {
        showValidationError = false
        
        if newIP.split(separator: ".").count != 4 && !newIP.contains(":") {
            validationErrorMessage = "Invalid IP Address format."
            showValidationError = true
            return
        }
        
        if newDomain.split(separator: ".").count < 2 {
            validationErrorMessage = "Invalid Hostname format (e.g. need domain extension)."
            showValidationError = true
            return
        }
        
        manager.addRecord(ip: newIP, domain: newDomain)
        newDomain = ""
    }
    
    private func saveChanges() {
        manager.saveHosts { success in
            if success {
                AppLogger.shared.log("DNS configuration synced successfully.")
            } else {
                AppLogger.shared.log("Hosts save operation aborted.")
            }
        }
    }
}
