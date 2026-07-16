import SwiftUI
import AppKit

struct appupdaterview: View {
    @StateObject private var manager = AppUpdateManager.shared
    @State private var filterType: SoftwareUpdateItem.UpdateType? = nil
    @State private var showAdoptAlert = false
    @State private var selectedItemForAdoption: SoftwareUpdateItem? = nil
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            headerSection()
            Divider()
            filterBar()
            Divider()

            if manager.isChecking {
                VStack(spacing: 12) {
                    ProgressView("Checking for software updates…").progressViewStyle(.circular)
                    Text("Scanning Homebrew repositories and App Store listings…")
                        .font(.caption).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if manager.updates.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.shield.fill").font(.system(size: 40)).foregroundStyle(.green)
                    Text("All Software is Up to Date").font(.headline)
                    Text("No outdated Homebrew casks, formulae, or App Store items were found.").font(.subheadline).foregroundColor(.secondary)
                    Button("Scan Again") {
                        manager.checkForUpdates()
                    }
                    .buttonStyle(.bordered).padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                updatesList()
            }

            Divider()
            logConsole()
            Divider()
            actionBar()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            manager.checkForUpdates()
        }
        .alert("Homebrew Cask Adoption", isPresented: $showAdoptAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Adopt", role: .destructive) {
                if let item = selectedItemForAdoption {
                    manager.adoptViaHomebrewCask(item) { success, msg in
                        alertMessage = msg
                    }
                }
            }
        } message: {
            if let item = selectedItemForAdoption {
                Text("This will reinstall '\(item.name)' via Homebrew Cask to replace your standalone copy. This allows future updates to be managed in a unified way via Juicer.\n\nProceed?")
            }
        }
    }

    // MARK: - Header
    @ViewBuilder
    private func headerSection() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Software Updates Desk")
                    .font(.title2).bold()
                Text("Unified dashboard for upgrading Homebrew, App Store, and Sparkle app packages. Migrate standalone apps to Cask management.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            
            Button(action: { manager.checkForUpdates() }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .disabled(manager.isChecking || manager.isUpdating)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }

    // MARK: - Filter Bar
    @ViewBuilder
    private func filterBar() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(action: { filterType = nil }) {
                    Text("All").font(.caption).bold()
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(filterType == nil ? Color.accentColor : Color.secondary.opacity(0.1))
                        .foregroundStyle(filterType == nil ? .white : .primary)
                        .cornerRadius(20)
                }
                .buttonStyle(.plain)

                ForEach(SoftwareUpdateItem.UpdateType.allCases, id: \.self) { type in
                    Button(action: { filterType = type }) {
                        Text(type.rawValue).font(.caption).bold()
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(filterType == type ? Color.accentColor : Color.secondary.opacity(0.1))
                            .foregroundStyle(filterType == type ? .white : .primary)
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal).padding(.vertical, 8)
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.2))
    }

    // MARK: - Updates List
    @ViewBuilder
    private func updatesList() -> some View {
        let filtered = filterType == nil ? manager.updates : manager.updates.filter { $0.type == filterType }
        
        List {
            ForEach(filtered) { item in
                HStack(spacing: 12) {
                    Toggle("", isOn: Binding(
                        get: { item.isSelected },
                        set: { val in
                            if let idx = manager.updates.firstIndex(where: { $0.id == item.id }) {
                                manager.updates[idx].isSelected = val
                            }
                        }
                    ))
                    .toggleStyle(.checkbox)
                    .disabled(manager.isUpdating)

                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(typeColor(item.type).opacity(0.12))
                            .frame(width: 30, height: 30)
                        Image(systemName: typeIcon(item.type))
                            .font(.caption).foregroundColor(typeColor(item.type))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text(item.name).font(.headline)
                            Text(item.type.rawValue.uppercased())
                                .font(.system(size: 8, weight: .bold))
                                .padding(.horizontal, 5).padding(.vertical, 1)
                                .background(typeColor(item.type).opacity(0.15))
                                .foregroundStyle(typeColor(item.type)).cornerRadius(3)
                        }
                        Text("Current: \(item.currentVersion) ➔ Latest: \(item.latestVersion)")
                            .font(.subheadline).foregroundColor(.secondary)
                    }

                    Spacer()

                    if item.type == .sparkle {
                        Button("Adopt via Cask") {
                            selectedItemForAdoption = item
                            showAdoptAlert = true
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.inset)
    }

    // MARK: - Log Console
    @ViewBuilder
    private func logConsole() -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Upgrade Execution Console").font(.caption).bold().foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal).padding(.vertical, 5)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.2))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    if manager.updateLog.isEmpty {
                        Text("Console idle. Trigger upgrade to see execution stream.")
                            .font(.system(.caption, design: .monospaced)).foregroundColor(.secondary)
                    } else {
                        ForEach(manager.updateLog, id: \.self) { line in
                            Text(line)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(line.hasPrefix("❌") ? .red : line.hasPrefix("✅") ? .green : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding()
            }
            .frame(height: 100)
            .background(Color(NSColor.underPageBackgroundColor).opacity(0.3))
        }
    }

    // MARK: - Action Bar
    @ViewBuilder
    private func actionBar() -> some View {
        HStack {
            let selectedCount = manager.updates.filter { $0.isSelected }.count
            Text("\(selectedCount) updates selected")
                .font(.subheadline).foregroundStyle(.secondary)
            Spacer()

            Button("Select All") {
                for i in manager.updates.indices { manager.updates[i].isSelected = true }
            }
            .buttonStyle(.bordered)
            .disabled(manager.isUpdating)

            Button("Select None") {
                for i in manager.updates.indices { manager.updates[i].isSelected = false }
            }
            .buttonStyle(.bordered)
            .disabled(manager.isUpdating)

            Button(action: {
                manager.updateSelected { _ in }
            }) {
                HStack {
                    if manager.isUpdating {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    }
                    Text("Upgrade Selected Packages")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedCount == 0 || manager.isUpdating || manager.isChecking)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }

    // MARK: - Helpers
    private func typeColor(_ type: SoftwareUpdateItem.UpdateType) -> Color {
        switch type {
        case .cask: return .orange
        case .formula: return .teal
        case .appStore: return .blue
        case .sparkle: return .purple
        }
    }

    private func typeIcon(_ type: SoftwareUpdateItem.UpdateType) -> String {
        switch type {
        case .cask: return "shippingbox.fill"
        case .formula: return "hammer.fill"
        case .appStore: return "square.grid.3x3.fill"
        case .sparkle: return "sparkles"
        }
    }
}
