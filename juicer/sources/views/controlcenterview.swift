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
    @State private var loginError = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                menuBarSection
                appBehaviorSection
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
}
