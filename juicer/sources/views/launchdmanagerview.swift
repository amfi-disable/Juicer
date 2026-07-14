import SwiftUI

struct launchdmanagerview: View {
    @StateObject private var manager = LaunchdManager()
    @State private var searchText = ""
    @State private var selectedService: LaunchdService?
    @State private var plistContent: String = ""
    @State private var isShowingEditor = false
    @State private var isCreatingNew = false
    
    // Editor Form States
    @State private var editLabel = ""
    @State private var editProgramArguments = ""
    @State private var editRunAtLoad = false
    @State private var editKeepAlive = false
    @State private var editPlistPath = ""
    
    var filteredServices: [LaunchdService] {
        if searchText.isEmpty {
            return manager.services
        } else {
            return manager.services.filter {
                $0.label.localizedCaseInsensitiveContains(searchText) ||
                $0.filepath.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Search & Create Toolbar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search service...", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button(action: createNewService) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.plain)
                    .help("Create New Launch Task")
                }
                .padding(10)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                
                // List of launchd tasks
                List(filteredServices, selection: $selectedService) { service in
                    NavigationLink(value: service) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(service.label)
                                    .font(.headline)
                                    .lineLimit(1)
                                Text(service.type)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            // Badge indicating running or stopped
                            statusBadge(for: service)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.sidebar)
            }
            .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 350)
        } detail: {
            if let service = selectedService {
                detailView(for: service)
            } else {
                VStack {
                    Image(systemName: "cpu")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary.opacity(0.8))
                        .padding(.bottom, 8)
                    Text("Select a Service")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.secondary)
                    Text("Choose any launch agent or daemon from the list to inspect or control it.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
        }
        .onAppear {
            manager.loadServices()
        }
        .onChange(of: selectedService) { _, newService in
            if let service = newService {
                loadPlistContent(for: service)
            }
        }
        .sheet(isPresented: $isShowingEditor) {
            editorSheet()
        }
    }
    
    // MARK: - Detail View UI
    @ViewBuilder
    private func detailView(for service: LaunchdService) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(service.label)
                        .font(.title2)
                        .bold()
                    Text(service.type)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Control Buttons
                HStack(spacing: 12) {
                    Button(service.pid != nil ? "Stop / Unload" : "Start / Load") {
                        manager.toggleServiceState(service) { success in
                            if success {
                                AppLogger.shared.log("Toggled status for \(service.label)")
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(service.pid != nil ? .red : .accentColor)
                    
                    Button("Edit...") {
                        openEditor(for: service)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(role: .destructive, action: { deleteService(service) }) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            
            Divider()
            
            // Metadata / Path Cards
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Plist Path:")
                        .bold()
                        .frame(width: 80, alignment: .leading)
                    Text(service.filepath)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Button(action: { NSWorkspace.shared.selectFile(service.filepath, inFileViewerRootedAtPath: "") }) {
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .help("Show in Finder")
                }
                
                HStack {
                    Text("Command:")
                        .bold()
                        .frame(width: 80, alignment: .leading)
                    Text(service.commandLine.isEmpty ? "None specified" : service.commandLine)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                HStack {
                    Text("Options:")
                        .bold()
                        .frame(width: 80, alignment: .leading)
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: service.runAtLoad ? "checkmark.circle.fill" : "xmark.circle")
                                .foregroundColor(service.runAtLoad ? .green : .secondary)
                            Text("Run At Load")
                        }
                        HStack(spacing: 4) {
                            Image(systemName: service.keepAlive ? "checkmark.circle.fill" : "xmark.circle")
                                .foregroundColor(service.keepAlive ? .green : .secondary)
                            Text("Keep Alive")
                        }
                    }
                    .font(.subheadline)
                }
            }
            .padding()
            
            Divider()
            
            // Code Viewer
            VStack(alignment: .leading, spacing: 8) {
                Text("Configuration Plist Source")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                ScrollView {
                    Text(plistContent)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                .cornerRadius(8)
                .padding([.horizontal, .bottom])
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Editor Sheet
    @ViewBuilder
    private func editorSheet() -> some View {
        VStack(spacing: 20) {
            Text(isCreatingNew ? "Create Launch Task" : "Edit Launch Task")
                .font(.title2)
                .bold()
            
            Form {
                TextField("Label (Unique ID):", text: $editLabel)
                    .disabled(!isCreatingNew) // Immutable label after creation
                
                TextField("Program Arguments:", text: $editProgramArguments)
                    .help("Provide command arguments separated by spaces.")
                
                Toggle("Run At Load", isOn: $editRunAtLoad)
                Toggle("Keep Alive", isOn: $editKeepAlive)
                
                if isCreatingNew {
                    Picker("Save Destination:", selection: $editPlistPath) {
                        Text("User Agents (~/Library/LaunchAgents)").tag("user")
                        Text("Global Agents (/Library/LaunchAgents)").tag("globalAgent")
                        Text("Global Daemons (/Library/LaunchDaemons)").tag("globalDaemon")
                    }
                    .pickerStyle(.radioGroup)
                } else {
                    TextField("File Destination:", text: $editPlistPath)
                        .disabled(true)
                }
            }
            .padding(.horizontal)
            
            HStack {
                Spacer()
                Button("Cancel") {
                    isShowingEditor = false
                }
                .buttonStyle(.bordered)
                
                Button("Save") {
                    saveEditorChanges()
                }
                .buttonStyle(.borderedProminent)
                .disabled(editLabel.isEmpty || editProgramArguments.isEmpty)
            }
            .padding()
        }
        .frame(width: 480, height: 380)
        .padding()
    }
    
    // MARK: - Helper UI Components
    @ViewBuilder
    private func statusBadge(for service: LaunchdService) -> some View {
        let isRunning = service.pid != nil
        Text(isRunning ? "Active" : "Stopped")
            .font(.caption2)
            .bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isRunning ? Color.green.opacity(0.15) : Color.secondary.opacity(0.15))
            .foregroundColor(isRunning ? .green : .secondary)
            .cornerRadius(8)
    }
    
    // MARK: - Logic Helpers
    private func loadPlistContent(for service: LaunchdService) {
        if let content = try? String(contentsOf: service.plistURL, encoding: .utf8) {
            self.plistContent = content
        } else {
            self.plistContent = "Could not load plist contents."
        }
    }
    
    private func openEditor(for service: LaunchdService) {
        self.isCreatingNew = false
        self.editLabel = service.label
        self.editProgramArguments = service.programArguments.joined(separator: " ")
        self.editRunAtLoad = service.runAtLoad
        self.editKeepAlive = service.keepAlive
        self.editPlistPath = service.plistURL.path
        self.isShowingEditor = true
    }
    
    private func createNewService() {
        self.isCreatingNew = true
        self.editLabel = "com.user.launchtask"
        self.editProgramArguments = "/usr/bin/say hello"
        self.editRunAtLoad = true
        self.editKeepAlive = false
        self.editPlistPath = "user"
        self.isShowingEditor = true
    }
    
    private func saveEditorChanges() {
        let plistURL: URL
        let type: String
        
        if isCreatingNew {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            let filename = "\(editLabel).plist"
            
            switch editPlistPath {
            case "globalAgent":
                plistURL = URL(fileURLWithPath: "/Library/LaunchAgents/\(filename)")
                type = "Global Agent"
            case "globalDaemon":
                plistURL = URL(fileURLWithPath: "/Library/LaunchDaemons/\(filename)")
                type = "Global Daemon"
            default:
                plistURL = URL(fileURLWithPath: "\(home)/Library/LaunchAgents/\(filename)")
                type = "User Agent"
            }
        } else {
            plistURL = URL(fileURLWithPath: editPlistPath)
            type = selectedService?.type ?? "User Agent"
        }
        
        let args = editProgramArguments.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        let service = LaunchdService(
            label: editLabel,
            programArguments: args,
            runAtLoad: editRunAtLoad,
            keepAlive: editKeepAlive,
            plistURL: plistURL,
            type: type
        )
        
        manager.saveService(service) { success in
            if success {
                self.isShowingEditor = false
                self.selectedService = service
            }
        }
    }
    
    private func deleteService(_ service: LaunchdService) {
        let alert = NSAlert()
        alert.messageText = "Delete Launch Task?"
        alert.informativeText = "Are you sure you want to permanently delete the launch task plist file at '\(service.filename)'? This will unload the process."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            manager.deleteService(service) { success in
                if success {
                    self.selectedService = nil
                }
            }
        }
    }
}
