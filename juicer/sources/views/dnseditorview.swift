import SwiftUI

struct dnseditorview: View {
    @StateObject private var manager = DNSManager()
    
    // New Record input fields
    @State private var newIP = "127.0.0.1"
    @State private var newDomain = ""
    @State private var showValidationError = false
    @State private var validationErrorMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection()
            
            // Add entry form
            addEntryForm()
                .padding()
            
            // Host records list
            if manager.isLoading {
                loadingPlaceholder()
            } else if manager.records.isEmpty {
                emptyStatePlaceholder()
            } else {
                recordsList()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.underlyingWindowBackgroundColor))
        .onAppear {
            manager.loadHosts()
        }
    }
    
    // MARK: - Header UI
    @ViewBuilder
    private func headerSection() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("DNS & /etc/hosts Editor")
                    .font(.title2)
                    .bold()
                Text("Manage local DNS mappings securely. Saving changes requires admin authentication.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            
            Button(action: { manager.loadHosts() }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Reload")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
            .disabled(manager.isLoading || manager.isSaving)
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
            Text("Reading hosts configuration...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State UI
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
            Text("We couldn't parse any local records. Add some to get started!")
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
                Text("System mappings are protected and cannot be disabled.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button(action: saveChanges) {
                    if manager.isSaving {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.5)
                    } else {
                        Text("Save & Sync DNS")
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
    
    // MARK: - Actions
    private func addRecord() {
        showValidationError = false
        
        // Simple validations
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
