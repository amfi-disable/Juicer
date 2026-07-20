import SwiftUI
import AppKit
import ServiceManagement

struct controlcenterview: View {
    @AppStorage("juicer.settings.showStatusMenuBar") private var showStatusMenuBar = true
    @AppStorage("juicer.settings.showQuickSendMenuBar") private var showQuickSendMenuBar = true
    @AppStorage("juicer.settings.menuBarLabelStyle") private var menuBarLabelStyle = "label"
    @AppStorage("juicer.settings.launchAtLogin") private var launchAtLogin = false
    @AppStorage("juicer.settings.confirmDestructiveActions") private var confirmDestructiveActions = true
    @AppStorage("juicer.settings.restoreMainWindow") private var restoreMainWindow = true
    @AppStorage("juicer.settings.showStatusBar") private var showStatusBar = true
    @AppStorage("juicer.settings.statusMonitorRefresh") private var refreshInterval = "2s"
    @AppStorage("juicer.settings.appearance") private var appearance = "system"
    @AppStorage("juicer.settings.accentColor") private var accentColor = "orange"
    @AppStorage("juicer.settings.sidebarWidth") private var sidebarWidth = 240
    @AppStorage("juicer.settings.compactNavigation") private var compactNavigation = false
    @AppStorage("juicer.settings.hideRecentNavigation") private var hideRecentNavigation = false
    @AppStorage("juicer.settings.hubDensity") private var hubDensity = "comfortable"
    @AppStorage("juicer.additionalFeatures.layout") private var catalogLayout = "list"
    @AppStorage("juicer.additionalFeatures.showDetails") private var catalogDetails = true
    @AppStorage("juicer.dashboard.showVitals") private var showVitals = true
    @AppStorage("juicer.dashboard.showCuratedTools") private var showCuratedTools = true
    @AppStorage("juicer.dashboard.showBookmarks") private var showBookmarks = true
    @AppStorage("juicer.settings.backgroundChecks") private var backgroundChecks = true
    @AppStorage("juicer.settings.lowDiskAlerts") private var lowDiskAlerts = true
    @AppStorage("juicer.settings.updateAlerts") private var updateAlerts = true
    @AppStorage("juicer.settings.backgroundInterval") private var backgroundInterval = 3600
    @AppStorage("juicer.settings.safeMode") private var safeMode = false
    @AppStorage("juicer.settings.previewBeforeDelete") private var previewBeforeDelete = true
    @AppStorage("juicer.settings.maskSensitiveLogs") private var maskSensitiveLogs = true
    @AppStorage("juicer.settings.workspaceProfile") private var workspaceProfile = "standard"
    @State private var loginError = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                appearanceSection
                menuBarSection
                appBehaviorSection
                safetySection
                dashboardSection
                automationSection
                permissionSection
            }
            .padding(24)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Juicer Control Center", systemImage: "switch.2")
                .font(.title2.bold())
            Text("Tune the main window, menu-bar extensions, permissions, and safety defaults from one place.")
                .foregroundStyle(.secondary)
        }
    }

    private var menuBarSection: some View {
        settingsCard(title: "Menu Bar", icon: "menubar.arrow.up.rectangle") {
            Toggle("Show Juicer Status in the menu bar", isOn: $showStatusMenuBar)
            Toggle("Show AirDrop Quick-Send in the menu bar", isOn: $showQuickSendMenuBar)
            Picker("Status item appearance", selection: $menuBarLabelStyle) {
                Text("Icon and label").tag("label")
                Text("Icon only").tag("icon")
            }
            .pickerStyle(.segmented)
            Text("Menu-bar status items appear on the right side of the macOS menu bar. The application menu and Cmd+, remain on the left when Juicer is the active main window.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var appearanceSection: some View {
        settingsCard(title: "Appearance", icon: "paintpalette") {
            Picker("Color scheme", selection: $appearance) {
                Text("Follow macOS").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.segmented)
            Picker("Accent color", selection: $accentColor) {
                Text("Orange").tag("orange")
                Text("Blue").tag("blue")
                Text("Purple").tag("purple")
                Text("Green").tag("green")
                Text("Pink").tag("pink")
            }
            .pickerStyle(.menu)
            Picker("Sidebar width", selection: $sidebarWidth) {
                Text("Compact").tag(210)
                Text("Standard").tag(240)
                Text("Wide").tag(290)
            }
            .pickerStyle(.segmented)
            Toggle("Compact navigation (icons until searched)", isOn: $compactNavigation)
            Toggle("Hide recent tools from the sidebar", isOn: $hideRecentNavigation)
            Picker("Hub card density", selection: $hubDensity) {
                Text("Comfortable").tag("comfortable")
                Text("Compact").tag("compact")
            }
            .pickerStyle(.segmented)
            Picker("Feature catalog layout", selection: $catalogLayout) {
                Text("List").tag("list")
                Text("Grid").tag("grid")
            }
            .pickerStyle(.segmented)
            Toggle("Show catalog descriptions", isOn: $catalogDetails)
        }
    }

    private var dashboardSection: some View {
        settingsCard(title: "Dashboard Layout", icon: "rectangle.3.group") {
            Toggle("Show system vitals", isOn: $showVitals)
            Toggle("Show recommended tools", isOn: $showCuratedTools)
            Toggle("Show bookmarks and shortcuts", isOn: $showBookmarks)
            Text("Changes apply immediately to the Dashboard workspace.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var safetySection: some View {
        settingsCard(title: "Safety and Profiles", icon: "checkmark.shield") {
            Picker("Workspace profile", selection: Binding(
                get: { workspaceProfile },
                set: { workspaceProfile = $0; applyProfile($0) }
            )) {
                Text("Standard").tag("standard")
                Text("Minimal").tag("minimal")
                Text("Monitoring").tag("monitoring")
                Text("Maintenance").tag("maintenance")
            }
            .pickerStyle(.segmented)
            Toggle("Safe mode (disable background automation)", isOn: $safeMode)
            Toggle("Preview destructive cleanup results first", isOn: $previewBeforeDelete)
            Toggle("Mask likely secrets in the local action log", isOn: $maskSensitiveLogs)
            Text("Profiles adjust visibility and monitoring defaults. Individual settings remain editable after selecting a profile.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var appBehaviorSection: some View {
        settingsCard(title: "App Behavior", icon: "gearshape.2") {
            Toggle("Launch Juicer at login", isOn: Binding(
                get: { launchAtLogin },
                set: { setLaunchAtLogin($0) }
            ))
            Toggle("Restore and focus the main window when opened", isOn: $restoreMainWindow)
            Toggle("Show the live status bar inside the main window", isOn: $showStatusBar)
            Toggle("Confirm destructive actions", isOn: $confirmDestructiveActions)
            Picker("Live status refresh interval", selection: $refreshInterval) {
                Text("1 second").tag("1s")
                Text("2 seconds").tag("2s")
                Text("5 seconds").tag("5s")
                Text("10 seconds").tag("10s")
                Text("30 seconds").tag("30s")
                Text("Manual").tag("Manual")
            }
            .pickerStyle(.menu)
            if !loginError.isEmpty {
                Text(loginError).font(.caption).foregroundStyle(.red)
            }
            HStack {
                Button("Export Settings…") { exportSettings() }
                Button("Import Settings…") { importSettings() }
            }
            Text("Settings backups are local plist files and never leave this Mac unless you move them yourself.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var permissionSection: some View {
        settingsCard(title: "Permissions", icon: "lock.shield") {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Permission Center").font(.headline)
                    Text("Request or review Accessibility, Screen Recording, Full Disk Access, notifications, and other protected services.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Open Permission Center") {
                    NSApp.activate(ignoringOtherApps: true)
                    NotificationCenter.default.post(name: NSNotification.Name("juicer.nav.permissionCenter"), object: nil)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var automationSection: some View {
        settingsCard(title: "Background Automation", icon: "clock.badge.checkmark") {
            Toggle("Run background checks", isOn: $backgroundChecks)
            Toggle("Notify about low disk space", isOn: $lowDiskAlerts)
            Toggle("Notify about available package updates", isOn: $updateAlerts)
            Picker("Check frequency", selection: $backgroundInterval) {
                Text("Every hour").tag(3600)
                Text("Every 6 hours").tag(21600)
                Text("Once a day").tag(86400)
            }
            .pickerStyle(.menu)
            Text("Background checks use local disk statistics and the existing package-update service. Notifications remain controlled by macOS.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func settingsCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon).font(.headline)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.45), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary))
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLogin = enabled
            loginError = ""
        } catch {
            loginError = "Could not update launch-at-login: \(error.localizedDescription)"
        }
    }

    private func exportSettings() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "juicer-settings.plist"
        panel.allowedFileTypes = ["plist"]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let values = UserDefaults.standard.persistentDomain(forName: Bundle.main.bundleIdentifier ?? "com.even.juicer") ?? [:]
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: values, format: .xml, options: 0)
            try data.write(to: url, options: .atomic)
            loginError = "Settings exported successfully."
        } catch {
            loginError = "Settings export failed: \(error.localizedDescription)"
        }
    }

    private func importSettings() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["plist"]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try Data(contentsOf: url)
            guard let values = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
                throw NSError(domain: "juicer.settings", code: 1, userInfo: [NSLocalizedDescriptionKey: "The selected file is not a Juicer settings backup."])
            }
            let domain = Bundle.main.bundleIdentifier ?? "com.even.juicer"
            UserDefaults.standard.setPersistentDomain(values, forName: domain)
            loginError = "Settings imported. Reopen Settings or Juicer to refresh every control."
        } catch {
            loginError = "Settings import failed: \(error.localizedDescription)"
        }
    }

    private func applyProfile(_ profile: String) {
        switch profile {
        case "minimal":
            showStatusBar = false
            showVitals = false
            showCuratedTools = false
            showBookmarks = true
        case "monitoring":
            showStatusBar = true
            showVitals = true
            showCuratedTools = true
            showBookmarks = false
            backgroundChecks = true
        case "maintenance":
            showStatusBar = true
            showVitals = true
            showCuratedTools = true
            showBookmarks = true
            backgroundChecks = true
            lowDiskAlerts = true
            updateAlerts = true
        default:
            showStatusBar = true
            showVitals = true
            showCuratedTools = true
            showBookmarks = true
        }
    }
}
