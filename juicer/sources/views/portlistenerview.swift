import SwiftUI

struct portlistenerview: View {
    @StateObject private var manager = PortManager()
    @State private var searchText = ""
    
    // UI Filters
    @State private var filterToDevPorts = true
    @State private var showGraphView = false
    @State private var showArgs = true
    
    // Process Kill Confirmation Alert State
    @State private var selectedPort: ActivePort?
    @State private var showFirstAlert = false
    @State private var showSecondAlert = false
    @State private var isKilling = false
    @State private var statusMessage = ""
    
    var filteredPorts: [ActivePort] {
        var list = manager.activePorts
        
        if filterToDevPorts {
            list = list.filter { PortManager.devPorts.contains($0.port) }
        }
        
        if !searchText.isEmpty {
            list = list.filter {
                String($0.port).contains(searchText) ||
                $0.processName.localizedCaseInsensitiveContains(searchText) ||
                String($0.pid).contains(searchText)
            }
        }
        
        return list
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Header Panel
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Port Listener & Process Killer")
                        .font(.title2)
                        .bold()
                    Text("Identify active listening sockets, trace parent processes, and terminate dangling developer servers.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                if manager.isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button(action: { manager.loadPorts() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            
            Divider()
            
            // Filters Toolbar
            HStack(spacing: 16) {
                // View toggle
                Picker("", selection: $showGraphView) {
                    Text("List View").tag(false)
                    Text("Process Network Graph").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 280)
                
                Toggle("Common Dev Ports", isOn: $filterToDevPorts)
                    .toggleStyle(.checkbox)
                
                Toggle("Show Arguments", isOn: $showArgs)
                    .toggleStyle(.checkbox)
                
                Spacer()
                
                // Search
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search Port, Name, PID...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
            }
            .padding()
            
            Divider()
            
            // Content Toggle
            if manager.isLoading {
                VStack {
                    ProgressView("Analyzing local network ports...")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredPorts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "network.badge.shield.half.filled")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No Listening Ports Detected")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("No processes are listening on the filtered ports. Start a server to test.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                if showGraphView {
                    graphViewContent()
                } else {
                    listViewContent()
                }
            }
            
            // Action status notification bar
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
        .onAppear {
            manager.loadPorts()
            
            // Sync settings options default values
            let showArgsSaved = UserDefaults.standard.bool(forKey: "juicer.settings.showProcessArgs")
            let filterDevSaved = UserDefaults.standard.bool(forKey: "juicer.settings.defaultToDevPorts")
            self.showArgs = showArgsSaved
            self.filterToDevPorts = filterDevSaved
        }
        // First Confirmation Alert
        .alert("Confirm Process Termination", isPresented: $showFirstAlert) {
            Button("Proceed", role: .none) {
                showSecondAlert = true
            }
            Button("Cancel", role: .cancel) {
                self.selectedPort = nil
            }
        } message: {
            if let port = selectedPort {
                Text("Are you sure you want to terminate process '\(port.processName)' (PID: \(port.pid)) listening on port \(port.port)?")
            }
        }
        // Second Confirmation Alert
        .alert("Final Verification Required", isPresented: $showSecondAlert) {
            Button("Force Terminate", role: .destructive) {
                executeProcessKill()
            }
            Button("Cancel", role: .cancel) {
                self.selectedPort = nil
            }
        } message: {
            if let port = selectedPort {
                let forceKill = UserDefaults.standard.bool(forKey: "juicer.settings.killForceful")
                Text("This will send a \(forceKill ? "SIGKILL (Force-Kill)" : "SIGTERM (Graceful)") signal. Unsaved work in the target process may be lost. Continue?")
            }
        }
    }
    
    // MARK: - Tabular List View
    @ViewBuilder
    private func listViewContent() -> some View {
        List {
            // Table Header Row
            HStack(spacing: 0) {
                Text("Port").bold().frame(width: 80, alignment: .leading)
                Text("Protocol").bold().frame(width: 80, alignment: .leading)
                Text("Process Name").bold().frame(width: 140, alignment: .leading)
                Text("PID").bold().frame(width: 80, alignment: .leading)
                Text("Parent PID").bold().frame(width: 100, alignment: .leading)
                if showArgs {
                    Text("Command Arguments").bold().frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Spacer()
                }
                Text("Action").bold().frame(width: 100, alignment: .center)
            }
            .padding(.vertical, 8)
            .foregroundColor(.secondary)
            
            Divider()
            
            ForEach(filteredPorts) { item in
                HStack(spacing: 0) {
                    // Port Badge
                    Text(String(item.port))
                        .font(.system(.body, design: .monospaced))
                        .bold()
                        .foregroundColor(.accentColor)
                        .frame(width: 80, alignment: .leading)
                    
                    Text(item.protocolName)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)
                    
                    Text(item.processName)
                        .bold()
                        .frame(width: 140, alignment: .leading)
                    
                    Text(String(item.pid))
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 80, alignment: .leading)
                    
                    Text(item.parentPid != nil ? String(item.parentPid!) : "System")
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    
                    if showArgs {
                        Text(item.commandLineArgs)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Spacer()
                    }
                    
                    Button("Kill") {
                        self.selectedPort = item
                        self.showFirstAlert = true
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .frame(width: 100, alignment: .center)
                    .disabled(isKilling)
                }
                .padding(.vertical, 6)
                Divider()
            }
        }
        .listStyle(.plain)
    }
    
    // MARK: - Process Relation Graph View
    @ViewBuilder
    private func graphViewContent() -> some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 30) {
                // Group active ports by parent PID to show branches
                let grouped = Dictionary(grouping: filteredPorts, by: { $0.parentPid ?? 0 })
                
                ForEach(grouped.keys.sorted(), id: \.self) { parentPid in
                    let ports = grouped[parentPid] ?? []
                    let parentName = ports.first?.parentPid == nil ? "System / launchd" : "Parent (PID: \(parentPid))"
                    
                    VStack(alignment: .leading, spacing: 10) {
                        // Parent Node Card
                        HStack {
                            Image(systemName: "cpu.fill")
                                .foregroundColor(.orange)
                            Text(parentName)
                                .font(.headline)
                        }
                        .padding(8)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(6)
                        
                        // Branches
                        HStack(alignment: .top, spacing: 40) {
                            // Visual branch line
                            VStack(spacing: 0) {
                                Circle().fill(Color.orange).frame(width: 6, height: 6)
                                Rectangle().fill(Color.orange.opacity(0.4)).frame(width: 2)
                            }
                            .padding(.leading, 12)
                            .frame(width: 30)
                            
                            // Children (Bound Processes)
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(ports) { item in
                                    HStack(spacing: 12) {
                                        // Process Card
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.processName)
                                                .bold()
                                            Text("PID: \(item.pid)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(10)
                                        .frame(width: 150, alignment: .leading)
                                        .background(Color(NSColor.controlBackgroundColor))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                        )
                                        
                                        // Arrow connector
                                        Image(systemName: "arrow.right")
                                            .foregroundColor(.accentColor)
                                        
                                        // Port Target Node
                                        HStack {
                                            Text("Port: \(item.port)")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.accentColor)
                                        .cornerRadius(8)
                                        
                                        // Kill Shortcut button
                                        Button(action: {
                                            self.selectedPort = item
                                            self.showFirstAlert = true
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.title3)
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(isKilling)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(10)
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Actions
    private func executeProcessKill() {
        guard let port = selectedPort else { return }
        
        self.isKilling = true
        self.statusMessage = "Sending termination signal to PID \(port.pid)..."
        
        manager.killProcess(pid: port.pid) { success in
            self.isKilling = false
            self.selectedPort = nil
            if success {
                self.statusMessage = "Successfully terminated process!"
            } else {
                self.statusMessage = "Failed to terminate process. Try enabling Force-Kill in Settings (Cmd + ,)."
            }
        }
    }
}
