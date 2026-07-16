import SwiftUI

struct brewtapsview: View {
    @StateObject private var manager = BrewTapsManager.shared
    @State private var searchText = ""
    @State private var newTapName = ""
    @State private var statusMessage = ""
    @State private var showStatusAlert = false
    @State private var isTapping = false
    
    var filteredTaps: [BrewTap] {
        if searchText.isEmpty {
            return manager.taps
        }
        return manager.taps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header panel
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Homebrew Taps Manager")
                        .font(.title2)
                        .bold()
                    Text("Register additional software repositories and audit sources health.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                if manager.isCheckingHealth {
                    HStack(spacing: 8) {
                        ProgressView().controlSize(.small)
                        Text("Auditing GitHub health...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button(action: { manager.checkTapsHealth() }) {
                        Label("Validate Health", systemImage: "shield.checkerboard")
                    }
                    .buttonStyle(.bordered)
                    .help("Runs GitHub API repository verification checks")
                }
                
                if manager.isLoading {
                    ProgressView().controlSize(.small)
                } else {
                    Button(action: { manager.loadTaps() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .help("Refresh Taps list")
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            
            Divider()
            
            // Add Tap Section
            HStack(spacing: 12) {
                TextField("Enter repository to tap (e.g. homebrew/cask-fonts or full URL)...", text: $newTapName)
                    .textFieldStyle(.roundedBorder)
                
                if isTapping {
                    ProgressView().controlSize(.small)
                } else {
                    Button("Tap Repository") {
                        tapRepository()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newTapName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.2))
            
            Divider()
            
            // Search toolbar
            HStack {
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search taps...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            // List of taps
            if filteredTaps.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "shippingbox.and.arrow.backward")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Repository Taps Registered")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredTaps) { tap in
                            tapRow(tap)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            manager.loadTaps()
        }
        .alert("Taps Operation", isPresented: $showStatusAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(statusMessage)
        }
    }
    
    // Row Builder
    @ViewBuilder
    private func tapRow(_ tap: BrewTap) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 10) {
                    Text(tap.name)
                        .font(.headline)
                        .bold()
                    
                    // Health status badge
                    if let health = tap.healthStatus {
                        healthBadge(health)
                    }
                }
                
                if !tap.remote.isEmpty {
                    Text(tap.remote)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Untap Button
            Button("Untap", role: .destructive) {
                removeTap(tap)
            }
            .buttonStyle(.bordered)
            .disabled(tap.name == "homebrew/core" || tap.name == "homebrew/cask") // Safeguard core taps
            .help((tap.name == "homebrew/core" || tap.name == "homebrew/cask") ? "Core taps cannot be unregistered." : "Remove tap repository.")
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // Health Badge builder
    @ViewBuilder
    private func healthBadge(_ health: TapHealthStatus) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(healthBadgeColor(health.status))
                .frame(width: 6, height: 6)
            
            Text(health.status.rawValue)
                .font(.system(size: 10, weight: .bold))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .foregroundColor(healthBadgeColor(health.status))
        .background(healthBadgeColor(health.status).opacity(0.15))
        .cornerRadius(4)
        .help(healthTooltip(health))
    }
    
    private func healthBadgeColor(_ status: TapHealthStatus.Status) -> Color {
        switch status {
        case .active: return .green
        case .stale: return .orange
        case .archived: return .gray
        case .redirected: return .teal
        case .missing: return .red
        case .unknown: return .primary
        }
    }
    
    private func healthTooltip(_ health: TapHealthStatus) -> String {
        switch health.status {
        case .active: return "Repository is active on GitHub. Checked on \(formatDate(health.lastChecked))."
        case .stale: return "Checked more than 24 hours ago. Please run Validate Health again."
        case .archived: return "WARNING: This repository is archived (read-only) on GitHub. No future package updates will be pushed."
        case .redirected: return "This repository has moved. Suggested location: \(health.movedTo ?? "unknown")."
        case .missing: return "CRITICAL ERROR: This repository returned 404. It has been deleted or made private."
        case .unknown: return "Health not validated yet."
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Action methods
    private func tapRepository() {
        let cleaned = newTapName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        
        isTapping = true
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .drawCompleted)
        
        manager.addTap(name: cleaned) { success in
            isTapping = false
            if success {
                newTapName = ""
                statusMessage = "Successfully tapped \(cleaned)!"
            } else {
                statusMessage = "Failed to tap \(cleaned). Verify name and internet connection."
            }
            showStatusAlert = true
        }
    }
    
    private func removeTap(_ tap: BrewTap) {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .drawCompleted)
        manager.removeTap(tap) { success in
            if success {
                statusMessage = "Successfully untapped \(tap.name)!"
            } else {
                statusMessage = "Failed to unregister \(tap.name)."
            }
            showStatusAlert = true
        }
    }
}
