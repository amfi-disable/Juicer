import SwiftUI

struct sdkmanagerview: View {
    @StateObject private var manager = SDKManager()
    
    // Switch state trackers
    @State private var selectedRuntime: SDKRuntime?
    @State private var targetVersion: String = ""
    @State private var showingFirstAlert = false
    @State private var showingSecondAlert = false
    @State private var statusMessage = ""
    @State private var isProcessing = false
    
    // Selection dictionaries to track selected dropdown values in UI
    @State private var selections: [String: String] = [:]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SDK & Runtime Switcher")
                        .font(.title2)
                        .bold()
                    Text("Manage active system versions of Node.js, Python, Ruby, Rust, and Homebrew links.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if manager.isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button(action: { manager.loadRuntimes() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .help("Refresh Runtimes List")
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            
            Divider()
            
            // Content
            if manager.isLoading {
                VStack {
                    ProgressView("Searching for installed SDK runtimes...")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if manager.runtimes.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "square.stack.3d.down.dotted.line")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No Version Managers Found")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Juicer did not detect any instances of nvm, fnm, pyenv, rbenv, rvm, or rustup installed in your home directory.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(manager.runtimes) { runtime in
                            runtimeCard(for: runtime)
                        }
                    }
                    .padding()
                }
            }
            
            // Status bar message
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
            manager.loadRuntimes()
        }
        // First Confirmation Alert
        .alert("Warning: Change Active Version?", isPresented: $showingFirstAlert) {
            Button("Proceed", role: .none) {
                showingSecondAlert = true
            }
            Button("Cancel", role: .cancel) {
                self.selectedRuntime = nil
                self.targetVersion = ""
            }
        } message: {
            if let runtime = selectedRuntime {
                Text("Are you sure you want to change the active version of \(runtime.name) to '\(targetVersion)'?")
            }
        }
        // Second Confirmation Alert
        .alert("Final Confirmation Required", isPresented: $showingSecondAlert) {
            Button("Confirm & Switch", role: .destructive) {
                executeVersionSwitch()
            }
            Button("Cancel", role: .cancel) {
                self.selectedRuntime = nil
                self.targetVersion = ""
            }
        } message: {
            if let runtime = selectedRuntime {
                Text("This will change the default global executable links of \(runtime.name) to '\(targetVersion)'. Do you want to apply this system change now?")
            }
        }
    }
    
    // MARK: - Runtime Card Component
    @ViewBuilder
    private func runtimeCard(for runtime: SDKRuntime) -> some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: iconName(for: runtime.type))
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(runtime.name)
                    .font(.headline)
                
                HStack(spacing: 6) {
                    Text("Active: \(runtime.activeVersion)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                }
            }
            
            Spacer()
            
            // Picker & Switch controls
            HStack(spacing: 12) {
                let currentSelection = selections[runtime.name] ?? runtime.activeVersion
                
                Picker("", selection: Binding(
                    get: { currentSelection },
                    set: { selections[runtime.name] = $0 }
                )) {
                    ForEach(runtime.installedVersions, id: \.self) { version in
                        Text(version).tag(version)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 140)
                
                Button("Switch") {
                    if let selected = selections[runtime.name], selected != runtime.activeVersion {
                        self.selectedRuntime = runtime
                        self.targetVersion = selected
                        self.showingFirstAlert = true
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isProcessing || (selections[runtime.name] ?? runtime.activeVersion) == runtime.activeVersion)
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
    
    // MARK: - Helpers
    private func iconName(for type: SDKRuntime.RuntimeType) -> String {
        switch type {
        case .nodeNvm, .nodeFnm:
            return "square.stack.3d.up.fill"
        case .pythonPyenv:
            return "curlybraces"
        case .rubyRbenv, .rubyRvm:
            return "suit.diamond.fill"
        case .rustRustup:
            return "gearshape.fill"
        case .brewRuntime:
            return "shippingbox.fill"
        }
    }
    
    private func executeVersionSwitch() {
        guard let runtime = selectedRuntime else { return }
        
        self.isProcessing = true
        self.statusMessage = "Applying version switch to \(targetVersion)..."
        
        manager.switchVersion(for: runtime, to: targetVersion) { success in
            self.isProcessing = false
            self.selectedRuntime = nil
            self.targetVersion = ""
            if success {
                self.statusMessage = "Successfully updated environment link!"
            } else {
                self.statusMessage = "Failed to switch version. Check log output."
            }
        }
    }
}
