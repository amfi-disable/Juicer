import SwiftUI
import AppKit

private struct additionalfeature: Identifiable {
    enum action {
        case settings(String)
        case folder(String)
        case copy(String)
        case command(String, [String])
    }

    let id: Int
    let title: String
    let detail: String
    let category: String
    let icon: String
    let action: action
}

struct additionalfeaturecatalogview: View {
    @State private var query = ""
    @State private var category = "All"
    @State private var message = ""
    @State private var favoritesOnly = false
    @AppStorage("juicer.additionalFeatures.favorites") private var favoriteIDs = ""
    @AppStorage("juicer.additionalFeatures.layout") private var layout = "list"
    @AppStorage("juicer.additionalFeatures.showDetails") private var showDetails = true

    private let categories = ["All", "System", "Privacy", "Developer", "Files", "Network", "Accessibility", "Hardware"]
    private let features = additionalfeaturecatalogview.catalog

    private var filtered: [additionalfeature] {
        features.filter { feature in
            (category == "All" || feature.category == category) &&
            (!favoritesOnly || favoriteSet.contains(feature.id)) &&
            (query.isEmpty || feature.title.localizedCaseInsensitiveContains(query) || feature.detail.localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Additional Features", subtitle: "One-click shortcuts for common macOS inspection and setup tasks.", icon: "square.grid.2x2", refreshing: false, action: {})

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    TextField("Search features & shortcuts...", text: $query)
                        .textFieldStyle(.roundedBorder)
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }
                    .frame(width: 140)
                }
                
                HStack(spacing: 14) {
                    Toggle("Favorites only", isOn: $favoritesOnly)
                        .toggleStyle(.checkbox)
                    
                    Toggle("Details", isOn: $showDetails)
                        .toggleStyle(.checkbox)
                    
                    Spacer()
                    
                    Picker("Layout", selection: $layout) {
                        Image(systemName: "list.bullet").tag("list")
                        Image(systemName: "square.grid.2x2").tag("grid")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 80)
                }
            }

            Text("\(filtered.count) available features")
                .font(.caption)
                .foregroundStyle(.secondary)

            if layout == "grid" {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 12)], spacing: 12) {
                    ForEach(filtered) { feature in featureCard(feature) }
                }
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(filtered) { feature in
                        featureCard(feature)
                        Divider()
                    }
                }
            }

            if !message.isEmpty { Text(message).font(.caption).foregroundStyle(.secondary) }
        }
        .padding(24)
    }

    @ViewBuilder
    private func featureCard(_ feature: additionalfeature) -> some View {
        HStack(spacing: 12) {
            Button { perform(feature) } label: {
                HStack(spacing: 12) {
                    Image(systemName: feature.icon)
                        .foregroundStyle(.tint)
                        .frame(width: 28, height: 28)
                        .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(feature.title).font(.headline)
                        if showDetails {
                            Text(feature.detail).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                        }
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "arrow.up.forward.app").font(.caption).foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button { toggleFavorite(feature.id) } label: {
                Image(systemName: favoriteSet.contains(feature.id) ? "star.fill" : "star")
                    .foregroundStyle(favoriteSet.contains(feature.id) ? .yellow : .secondary)
            }
            .buttonStyle(.plain)
            .help(favoriteSet.contains(feature.id) ? "Remove from favorites" : "Favorite this feature")
        }
        .padding(layout == "grid" ? 12 : 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(layout == "grid" ? Color(NSColor.controlBackgroundColor).opacity(0.45) : Color.clear, in: RoundedRectangle(cornerRadius: 10))
    }

    private func perform(_ feature: additionalfeature) {
        switch feature.action {
        case .settings(let pane):
            if let url = URL(string: "x-apple.systempreferences:\(pane)") { NSWorkspace.shared.open(url) }
            message = "Opened \(feature.title)."
        case .folder(let path):
            let expanded = NSString(string: path).expandingTildeInPath
            NSWorkspace.shared.open(URL(fileURLWithPath: expanded))
            message = "Opened \(expanded)."
        case .copy(let value):
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(value, forType: .string)
            message = "Copied \(feature.title) result to the clipboard."
        case .command(let executable, let arguments):
            let result = SystemMetricsSupport.run(executable, arguments) ?? "No result was returned."
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(result, forType: .string)
            message = "Copied command result to the clipboard."
        }
        AppLogger.shared.log("Ran additional feature: \(feature.title)")
    }

    private var favoriteSet: Set<Int> {
        Set(favoriteIDs.split(separator: ",").compactMap { Int($0) })
    }

    private func toggleFavorite(_ id: Int) {
        var updated = favoriteSet
        if updated.contains(id) { updated.remove(id) } else { updated.insert(id) }
        favoriteIDs = updated.sorted().map(String.init).joined(separator: ",")
    }

    private static let catalog: [additionalfeature] = [
        additionalfeature(id: 101, title: "Open General Settings", detail: "Jump directly to macOS General settings.", category: "System", icon: "gearshape", action: .settings("com.apple.preference.general")),
        additionalfeature(id: 102, title: "Open Appearance Settings", detail: "Change light, dark, accent, and sidebar appearance.", category: "System", icon: "circle.lefthalf.filled", action: .settings("com.apple.preference.general?Appearance")),
        additionalfeature(id: 103, title: "Open Desktop & Dock", detail: "Configure the Dock, desktop, and window behavior.", category: "System", icon: "dock.rectangle", action: .settings("com.apple.Desktop-Settings.extension")),
        additionalfeature(id: 104, title: "Open Displays", detail: "Manage displays, arrangement, and resolution.", category: "Hardware", icon: "display.2", action: .settings("com.apple.preference.displays")),
        additionalfeature(id: 105, title: "Open Sound", detail: "Manage input, output, and alert sound devices.", category: "Hardware", icon: "speaker.wave.2", action: .settings("com.apple.preference.sound")),
        additionalfeature(id: 106, title: "Open Keyboard Settings", detail: "Configure keyboard behavior and shortcuts.", category: "Accessibility", icon: "keyboard", action: .settings("com.apple.preference.keyboard")),
        additionalfeature(id: 107, title: "Open Trackpad Settings", detail: "Configure pointing and gesture behavior.", category: "Hardware", icon: "hand.draw", action: .settings("com.apple.preference.trackpad")),
        additionalfeature(id: 108, title: "Open Mouse Settings", detail: "Configure mouse tracking and scrolling.", category: "Hardware", icon: "computermouse", action: .settings("com.apple.preference.mouse")),
        additionalfeature(id: 109, title: "Open Printers & Scanners", detail: "Manage printers, scanners, and queues.", category: "Hardware", icon: "printer", action: .settings("com.apple.preference.printfax")),
        additionalfeature(id: 110, title: "Open Battery Settings", detail: "Review battery health and energy options.", category: "Hardware", icon: "battery.100", action: .settings("com.apple.preference.battery")),
        additionalfeature(id: 111, title: "Open Lock Screen", detail: "Configure password and screen lock behavior.", category: "Privacy", icon: "lock.display", action: .settings("com.apple.Lock-Screen-Settings.extension")),
        additionalfeature(id: 112, title: "Open Users & Groups", detail: "Review local user accounts and groups.", category: "System", icon: "person.2", action: .settings("com.apple.preference.users")),
        additionalfeature(id: 113, title: "Open Login Items", detail: "Manage apps that launch at login.", category: "System", icon: "arrow.up.forward.app", action: .settings("com.apple.LoginItems-Settings.extension")),
        additionalfeature(id: 114, title: "Open Date & Time", detail: "Configure time zone and clock synchronization.", category: "System", icon: "clock", action: .settings("com.apple.preference.datetime")),
        additionalfeature(id: 115, title: "Open Sharing", detail: "Review services shared from this Mac.", category: "Privacy", icon: "square.and.arrow.up", action: .settings("com.apple.preferences.sharing")),
        additionalfeature(id: 116, title: "Open Time Machine", detail: "Review backup destinations and schedules.", category: "Files", icon: "clock.arrow.circlepath", action: .settings("com.apple.TimeMachine-Settings.extension")),
        additionalfeature(id: 117, title: "Open Software Update", detail: "Check macOS update status.", category: "System", icon: "arrow.down.circle", action: .settings("com.apple.Software-Update-Settings.extension")),
        additionalfeature(id: 118, title: "Open Siri Settings", detail: "Configure Siri and voice feedback.", category: "Accessibility", icon: "waveform", action: .settings("com.apple.preference.speech")),
        additionalfeature(id: 119, title: "Open Spotlight Settings", detail: "Configure Spotlight search locations.", category: "System", icon: "magnifyingglass", action: .settings("com.apple.preference.spotlight")),
        additionalfeature(id: 120, title: "Open Mission Control", detail: "Configure Spaces and window overview behavior.", category: "System", icon: "rectangle.3.group", action: .settings("com.apple.preference.missioncontrol")),
        additionalfeature(id: 121, title: "Open Full Disk Access", detail: "Review apps allowed to access protected data.", category: "Privacy", icon: "lock.shield", action: .settings("com.apple.preference.security?Privacy_AllFiles")),
        additionalfeature(id: 122, title: "Open Accessibility Access", detail: "Review apps allowed to control the Mac.", category: "Privacy", icon: "accessibility", action: .settings("com.apple.preference.security?Privacy_Accessibility")),
        additionalfeature(id: 123, title: "Open Screen Recording Access", detail: "Review apps allowed to capture the screen.", category: "Privacy", icon: "record.circle", action: .settings("com.apple.preference.security?Privacy_ScreenCapture")),
        additionalfeature(id: 124, title: "Open Input Monitoring", detail: "Review apps allowed to monitor keyboard input.", category: "Privacy", icon: "keyboard.badge.ellipsis", action: .settings("com.apple.preference.security?Privacy_ListenEvent")),
        additionalfeature(id: 125, title: "Open Files & Folders Access", detail: "Review per-app file access grants.", category: "Privacy", icon: "folder.badge.gearshape", action: .settings("com.apple.preference.security?Privacy_FilesAndFolders")),
        additionalfeature(id: 126, title: "Open Location Access", detail: "Review apps using location services.", category: "Privacy", icon: "location.fill", action: .settings("com.apple.preference.security?Privacy_LocationServices")),
        additionalfeature(id: 127, title: "Open Camera Access", detail: "Review apps allowed to use the camera.", category: "Privacy", icon: "camera", action: .settings("com.apple.preference.security?Privacy_Camera")),
        additionalfeature(id: 128, title: "Open Microphone Access", detail: "Review apps allowed to use the microphone.", category: "Privacy", icon: "mic", action: .settings("com.apple.preference.security?Privacy_Microphone")),
        additionalfeature(id: 129, title: "Open Automation Access", detail: "Review apps allowed to automate other apps.", category: "Privacy", icon: "gearshape.2", action: .settings("com.apple.preference.security?Privacy_Automation")),
        additionalfeature(id: 130, title: "Open Developer Tools Access", detail: "Review developer tool permissions.", category: "Developer", icon: "hammer", action: .settings("com.apple.preference.security?Privacy_DeveloperTool")),
        additionalfeature(id: 131, title: "Open Xcode DerivedData", detail: "Reveal Xcode build products in Finder.", category: "Developer", icon: "hammer.fill", action: .folder("~/Library/Developer/Xcode/DerivedData")),
        additionalfeature(id: 132, title: "Open Xcode Archives", detail: "Reveal archived Xcode builds in Finder.", category: "Developer", icon: "archivebox", action: .folder("~/Library/Developer/Xcode/Archives")),
        additionalfeature(id: 133, title: "Open Xcode Devices", detail: "Reveal Xcode device support files.", category: "Developer", icon: "iphone.gen.3", action: .folder("~/Library/Developer/Xcode/iOS DeviceSupport")),
        additionalfeature(id: 134, title: "Open Swift Package Cache", detail: "Reveal Swift package checkouts.", category: "Developer", icon: "swift", action: .folder("~/Library/Caches/org.swift.swiftpm")),
        additionalfeature(id: 135, title: "Open npm Cache", detail: "Reveal the local npm cache.", category: "Developer", icon: "shippingbox", action: .folder("~/.npm")),
        additionalfeature(id: 136, title: "Open Yarn Cache", detail: "Reveal the local Yarn cache.", category: "Developer", icon: "shippingbox.fill", action: .folder("~/Library/Caches/Yarn")),
        additionalfeature(id: 137, title: "Open Cargo Registry", detail: "Reveal Rust registry downloads.", category: "Developer", icon: "shippingbox", action: .folder("~/.cargo/registry")),
        additionalfeature(id: 138, title: "Open Homebrew Cellar", detail: "Reveal installed Homebrew packages.", category: "Developer", icon: "mug", action: .folder("/opt/homebrew/Cellar")),
        additionalfeature(id: 139, title: "Open Python User Packages", detail: "Reveal user-installed Python packages.", category: "Developer", icon: "chevron.left.forwardslash.chevron.right", action: .folder("~/Library/Python")),
        additionalfeature(id: 140, title: "Open SSH Directory", detail: "Reveal SSH keys and configuration files.", category: "Developer", icon: "key", action: .folder("~/.ssh")),
        additionalfeature(id: 141, title: "Open Git Configuration", detail: "Reveal global Git configuration files.", category: "Developer", icon: "arrow.triangle.branch", action: .folder("~/.config/git")),
        additionalfeature(id: 142, title: "Open Docker Data", detail: "Reveal Docker Desktop support files.", category: "Developer", icon: "shippingbox.fill", action: .folder("~/Library/Containers/com.docker.docker")),
        additionalfeature(id: 143, title: "Open VS Code Extensions", detail: "Reveal installed VS Code extensions.", category: "Developer", icon: "puzzlepiece.extension", action: .folder("~/.vscode/extensions")),
        additionalfeature(id: 144, title: "Open JetBrains Settings", detail: "Reveal JetBrains application settings.", category: "Developer", icon: "gearshape", action: .folder("~/Library/Application Support/JetBrains")),
        additionalfeature(id: 145, title: "Open Terminal Profiles", detail: "Reveal Terminal profile files.", category: "Developer", icon: "terminal", action: .folder("~/Library/Preferences")),
        additionalfeature(id: 146, title: "Open Downloads", detail: "Reveal the current Downloads folder.", category: "Files", icon: "arrow.down.circle", action: .folder("~/Downloads")),
        additionalfeature(id: 147, title: "Open Desktop", detail: "Reveal the current Desktop folder.", category: "Files", icon: "menubar.dock.rectangle", action: .folder("~/Desktop")),
        additionalfeature(id: 148, title: "Open Documents", detail: "Reveal the current Documents folder.", category: "Files", icon: "doc", action: .folder("~/Documents")),
        additionalfeature(id: 149, title: "Open Application Support", detail: "Reveal per-user application data.", category: "Files", icon: "folder", action: .folder("~/Library/Application Support")),
        additionalfeature(id: 150, title: "Open Preferences", detail: "Reveal per-user preferences.", category: "Files", icon: "slider.horizontal.3", action: .folder("~/Library/Preferences")),
        additionalfeature(id: 151, title: "Open Logs", detail: "Reveal per-user application logs.", category: "Files", icon: "doc.text", action: .folder("~/Library/Logs")),
        additionalfeature(id: 152, title: "Open Saved Application State", detail: "Reveal saved application window state.", category: "Files", icon: "rectangle.on.rectangle", action: .folder("~/Library/Saved Application State")),
        additionalfeature(id: 153, title: "Open Fonts", detail: "Reveal user-installed fonts.", category: "Files", icon: "textformat", action: .folder("~/Library/Fonts")),
        additionalfeature(id: 154, title: "Open QuickLook Cache", detail: "Reveal QuickLook support files.", category: "Files", icon: "eye", action: .folder("~/Library/QuickLook")),
        additionalfeature(id: 155, title: "Open LaunchAgents", detail: "Reveal per-user launch agents.", category: "Files", icon: "arrow.up.forward.app", action: .folder("~/Library/LaunchAgents")),
        additionalfeature(id: 156, title: "Open Services Menu", detail: "Reveal user Services menu workflows.", category: "Files", icon: "gearshape.2", action: .folder("~/Library/Services")),
        additionalfeature(id: 157, title: "Open Network Settings", detail: "Configure Wi-Fi and network services.", category: "Network", icon: "network", action: .settings("com.apple.preference.network")),
        additionalfeature(id: 158, title: "Open Wi-Fi Settings", detail: "Jump directly to Wi-Fi controls.", category: "Network", icon: "wifi", action: .settings("com.apple.wifi-settings-extension")),
        additionalfeature(id: 159, title: "Open Bluetooth Settings", detail: "Manage nearby Bluetooth devices.", category: "Network", icon: "bluetooth", action: .settings("com.apple.BluetoothSettings")),
        additionalfeature(id: 160, title: "Open VPN Settings", detail: "Manage VPN configurations.", category: "Network", icon: "lock.shield", action: .settings("com.apple.preference.network?VPN")),
        additionalfeature(id: 161, title: "Open Firewall Settings", detail: "Review application firewall controls.", category: "Network", icon: "flame", action: .settings("com.apple.preference.security?Firewall")),
        additionalfeature(id: 162, title: "Open Extensions Settings", detail: "Manage system and app extensions.", category: "System", icon: "puzzlepiece.extension", action: .settings("com.apple.ExtensionsPreferences")),
        additionalfeature(id: 163, title: "Copy Local Hostname", detail: "Copy the Mac's local hostname.", category: "Network", icon: "network", action: .copy(ProcessInfo.processInfo.hostName)),
        additionalfeature(id: 164, title: "Copy Operating System Version", detail: "Copy the current macOS version string.", category: "System", icon: "info.circle", action: .copy(ProcessInfo.processInfo.operatingSystemVersionString)),
        additionalfeature(id: 165, title: "Copy Machine Model", detail: "Copy the reported Mac hardware model.", category: "Hardware", icon: "desktopcomputer", action: .copy("macOS hardware")),
        additionalfeature(id: 166, title: "Copy Home Directory", detail: "Copy the current user's home path.", category: "Files", icon: "house", action: .copy(NSHomeDirectory())),
        additionalfeature(id: 167, title: "Copy Temporary Directory", detail: "Copy the current temporary directory path.", category: "Files", icon: "folder.badge.gearshape", action: .copy(NSTemporaryDirectory())),
        additionalfeature(id: 168, title: "Copy Application Support Path", detail: "Copy the user Application Support path.", category: "Files", icon: "folder", action: .copy(FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.path ?? "")),
        additionalfeature(id: 169, title: "Copy Caches Path", detail: "Copy the user Caches path.", category: "Files", icon: "sparkles", action: .copy(FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.path ?? "")),
        additionalfeature(id: 170, title: "Copy Documents Path", detail: "Copy the user Documents path.", category: "Files", icon: "doc", action: .copy(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? "")),
        additionalfeature(id: 171, title: "Copy Downloads Path", detail: "Copy the user Downloads path.", category: "Files", icon: "arrow.down.circle", action: .copy(FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path ?? "")),
        additionalfeature(id: 172, title: "Copy Desktop Path", detail: "Copy the user Desktop path.", category: "Files", icon: "menubar.dock.rectangle", action: .copy(FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first?.path ?? "")),
        additionalfeature(id: 173, title: "Copy Library Path", detail: "Copy the user Library path.", category: "Files", icon: "books.vertical", action: .copy(FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?.path ?? "")),
        additionalfeature(id: 174, title: "Copy Application Path", detail: "Copy the user Applications path.", category: "Files", icon: "app.dashed", action: .copy(FileManager.default.urls(for: .applicationDirectory, in: .userDomainMask).first?.path ?? "")),
        additionalfeature(id: 175, title: "Copy Temporary File Path", detail: "Copy a fresh temporary file path.", category: "Files", icon: "doc.badge.plus", action: .copy(URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString).path)),
        additionalfeature(id: 176, title: "Open Screen Saver Settings", detail: "Configure screen saver behavior.", category: "Accessibility", icon: "rectangle.on.rectangle", action: .settings("com.apple.ScreenSaver-Settings.extension")),
        additionalfeature(id: 177, title: "Open Focus Settings", detail: "Configure Focus modes and schedules.", category: "System", icon: "moon", action: .settings("com.apple.Focus")),
        additionalfeature(id: 178, title: "Open Notifications Settings", detail: "Configure notification delivery.", category: "System", icon: "bell", action: .settings("com.apple.Notifications-Settings.extension")),
        additionalfeature(id: 179, title: "Open Internet Accounts", detail: "Manage connected account providers.", category: "Privacy", icon: "person.crop.circle", action: .settings("com.apple.preferences.internetaccounts")),
        additionalfeature(id: 180, title: "Open Wallet Settings", detail: "Review Wallet and payment preferences.", category: "Privacy", icon: "wallet.pass", action: .settings("com.apple.Passbook")),
        additionalfeature(id: 181, title: "Open Screen Time", detail: "Review app and website usage limits.", category: "System", icon: "hourglass", action: .settings("com.apple.Screen-Time-Settings.extension")),
        additionalfeature(id: 182, title: "Open Game Center", detail: "Configure Game Center preferences.", category: "System", icon: "gamecontroller", action: .settings("com.apple.preference.gamecenter")),
        additionalfeature(id: 183, title: "Open Sharing Extensions", detail: "Review available sharing extensions.", category: "System", icon: "square.and.arrow.up", action: .settings("com.apple.ExtensionsPreferences")),
        additionalfeature(id: 184, title: "Open Login Password Options", detail: "Configure login password requirements.", category: "Privacy", icon: "key", action: .settings("com.apple.Lock-Screen-Settings.extension")),
        additionalfeature(id: 185, title: "Open Touch ID Settings", detail: "Manage Touch ID enrollment and use.", category: "Privacy", icon: "touchid", action: .settings("com.apple.Touch-ID-Settings.extension")),
        additionalfeature(id: 186, title: "Open Siri & Spotlight", detail: "Configure assistant and search behavior.", category: "System", icon: "sparkles", action: .settings("com.apple.Siri-Settings.extension")),
        additionalfeature(id: 187, title: "Open Language & Region", detail: "Configure locale, calendar, and formats.", category: "System", icon: "globe", action: .settings("com.apple.Localization-Settings.extension")),
        additionalfeature(id: 188, title: "Open Transfer & Reset", detail: "Open migration and reset options.", category: "System", icon: "arrow.triangle.2.circlepath", action: .settings("com.apple.Transfer-Reset-Settings.extension")),
        additionalfeature(id: 189, title: "Open AirDrop Settings", detail: "Configure AirDrop discoverability.", category: "Network", icon: "airplayaudio", action: .settings("com.apple.Sharing-Settings.extension")),
        additionalfeature(id: 190, title: "Open Handoff Settings", detail: "Configure Continuity and Handoff.", category: "Network", icon: "rectangle.on.rectangle", action: .settings("com.apple.preference.general?Handoff")),
        additionalfeature(id: 191, title: "Open Accessibility Display", detail: "Configure zoom, contrast, and display accessibility.", category: "Accessibility", icon: "eye", action: .settings("com.apple.preference.universalaccess?Seeing_Display")),
        additionalfeature(id: 192, title: "Open Accessibility Zoom", detail: "Configure screen zoom options.", category: "Accessibility", icon: "plus.magnifyingglass", action: .settings("com.apple.preference.universalaccess?Seeing_Zoom")),
        additionalfeature(id: 193, title: "Open Accessibility VoiceOver", detail: "Configure VoiceOver navigation.", category: "Accessibility", icon: "figure.wave", action: .settings("com.apple.preference.universalaccess?Seeing_VoiceOver")),
        additionalfeature(id: 194, title: "Open Accessibility Hearing", detail: "Configure audio and caption accessibility.", category: "Accessibility", icon: "ear", action: .settings("com.apple.preference.universalaccess?Hearing")),
        additionalfeature(id: 195, title: "Open Accessibility Motor", detail: "Configure pointer and keyboard accessibility.", category: "Accessibility", icon: "figure.walk", action: .settings("com.apple.preference.universalaccess?Motor")),
        additionalfeature(id: 196, title: "Open Accessibility Speech", detail: "Configure spoken content and live speech.", category: "Accessibility", icon: "text.bubble", action: .settings("com.apple.preference.universalaccess?SpeakableItems")),
        additionalfeature(id: 197, title: "Open Date Formats", detail: "Configure regional date and number formats.", category: "System", icon: "calendar", action: .settings("com.apple.Localization-Settings.extension")),
        additionalfeature(id: 198, title: "Open Default Browser", detail: "Choose the default web browser.", category: "System", icon: "globe", action: .settings("com.apple.DefaultApps-Settings.extension")),
        additionalfeature(id: 199, title: "Open Default Email", detail: "Choose the default email client.", category: "System", icon: "envelope", action: .settings("com.apple.DefaultApps-Settings.extension")),
        additionalfeature(id: 200, title: "Open Juicer Preferences", detail: "Open Juicer's own settings window.", category: "System", icon: "gearshape.2", action: .settings("com.even.juicer")),

        // System and maintenance
        additionalfeature(id: 201, title: "Smart Maintenance Summary", detail: "Copy a compact system version and uptime summary.", category: "System", icon: "wand.and.stars", action: .command("/bin/sh", ["-c", "/usr/bin/sw_vers; /usr/bin/uptime"])),
        additionalfeature(id: 202, title: "macOS Update Readiness", detail: "Copy the current macOS version and hardware platform.", category: "System", icon: "checkmark.seal", action: .command("/bin/sh", ["-c", "/usr/bin/sw_vers; /usr/bin/uname -m"])),
        additionalfeature(id: 203, title: "System Integrity Snapshot", detail: "Copy basic System Integrity Protection status.", category: "Privacy", icon: "checkmark.shield", action: .command("/usr/bin/csrutil", ["status"])),
        additionalfeature(id: 204, title: "Kernel Extension Inventory", detail: "Copy the installed legacy kernel extension inventory.", category: "System", icon: "puzzlepiece.extension", action: .command("/usr/bin/kmutil", ["showloaded"])),
        additionalfeature(id: 205, title: "Login Item Impact Score", detail: "Copy current login item process information for review.", category: "System", icon: "gauge.with.dots.needle.67percent", action: .command("/bin/launchctl", ["list"])),
        additionalfeature(id: 206, title: "Background Activity Timeline", detail: "Copy currently running user agents and services.", category: "System", icon: "timeline.selection", action: .command("/bin/launchctl", ["list"])),
        additionalfeature(id: 207, title: "Restart Requirement Check", detail: "Copy pending software update and restart indicators.", category: "System", icon: "arrow.clockwise.circle", action: .command("/usr/bin/softwareupdate", ["--list"])),
        additionalfeature(id: 208, title: "System Uptime History", detail: "Copy the current uptime and load averages.", category: "System", icon: "clock.arrow.circlepath", action: .command("/usr/bin/uptime", [])),
        additionalfeature(id: 209, title: "Sleep and Wake History", detail: "Copy recent power-management sleep and wake events.", category: "System", icon: "moon.zzz", action: .command("/usr/bin/pmset", ["-g", "log"])),
        additionalfeature(id: 210, title: "Unexpected Shutdown Report", detail: "Copy recent shutdown and restart records.", category: "System", icon: "exclamationmark.triangle", action: .command("/usr/bin/last", ["-x", "-5"])),

        // Storage and files
        additionalfeature(id: 211, title: "Storage Cleanup Planner", detail: "Open the main storage locations for cleanup planning.", category: "Files", icon: "chart.bar.xaxis", action: .folder("~/Library")),
        additionalfeature(id: 212, title: "APFS Volume Manager", detail: "Copy APFS volume and container information.", category: "Files", icon: "externaldrive.fill", action: .command("/usr/sbin/diskutil", ["apfs", "list"])),
        additionalfeature(id: 213, title: "Time Machine Snapshot Browser", detail: "Copy local Time Machine snapshot names.", category: "Files", icon: "clock.arrow.circlepath", action: .command("/usr/bin/tmutil", ["listlocalsnapshots", "/"])),
        additionalfeature(id: 214, title: "Trash Size Analyzer", detail: "Open the current user's Trash for review.", category: "Files", icon: "trash", action: .folder("~/.Trash")),
        additionalfeature(id: 215, title: "File Age Heatmap", detail: "Open Downloads for age-based file review.", category: "Files", icon: "calendar.badge.clock", action: .folder("~/Downloads")),
        additionalfeature(id: 216, title: "Folder Permission Analyzer", detail: "Open the home folder for permission inspection.", category: "Privacy", icon: "lock.document", action: .folder("~")),
        additionalfeature(id: 217, title: "File Ownership Repair", detail: "Open Application Support for ownership review.", category: "Files", icon: "person.crop.circle", action: .folder("~/Library/Application Support")),
        additionalfeature(id: 218, title: "Broken Alias Finder", detail: "Open Desktop for alias review.", category: "Files", icon: "link.badge.plus", action: .folder("~/Desktop")),
        additionalfeature(id: 219, title: "Symbolic Link Repair Queue", detail: "Open the home folder before repairing links.", category: "Files", icon: "link", action: .folder("~")),
        additionalfeature(id: 220, title: "File Name Normalizer", detail: "Open Downloads for safe file-name cleanup.", category: "Files", icon: "textformat.abc", action: .folder("~/Downloads")),

        // Applications
        additionalfeature(id: 221, title: "Application Launch Profiler", detail: "Copy currently running applications and process IDs.", category: "System", icon: "speedometer", action: .command("/bin/ps", ["-axo", "pid,etime,comm"])),
        additionalfeature(id: 222, title: "Application Crash Reports", detail: "Open the local diagnostic reports folder.", category: "System", icon: "exclamationmark.square", action: .folder("~/Library/Logs/DiagnosticReports")),
        additionalfeature(id: 223, title: "App Sandbox Entitlements", detail: "Open the Applications folder for inspection.", category: "Privacy", icon: "shippingbox", action: .folder("/Applications")),
        additionalfeature(id: 224, title: "Application Notarization Check", detail: "Copy Gatekeeper assessment instructions.", category: "Privacy", icon: "checkmark.shield", action: .copy("spctl --assess --type execute --verbose /path/to/app")),
        additionalfeature(id: 225, title: "Application Signature Verifier", detail: "Copy codesign verification instructions.", category: "Privacy", icon: "signature", action: .copy("codesign --verify --deep --strict --verbose=2 /path/to/app")),
        additionalfeature(id: 226, title: "Application Architecture Detector", detail: "Copy the current Mac architecture.", category: "System", icon: "cpu", action: .command("/usr/bin/uname", ["-m"])),
        additionalfeature(id: 227, title: "Rosetta Usage Tracker", detail: "Copy the architecture of running processes.", category: "System", icon: "arrow.triangle.2.circlepath", action: .command("/bin/ps", ["-axo", "pid,comm"])),
        additionalfeature(id: 228, title: "App Dependency Viewer", detail: "Copy shared library inspection instructions.", category: "Developer", icon: "point.3.connected.trianglepath.dotted", action: .copy("otool -L /path/to/app/Contents/MacOS/app")),
        additionalfeature(id: 229, title: "App Version History", detail: "Open Applications for version comparison.", category: "System", icon: "clock.arrow.circlepath", action: .folder("/Applications")),
        additionalfeature(id: 230, title: "Removed App History", detail: "Open saved application state for review.", category: "Files", icon: "trash.slash", action: .folder("~/Library/Saved Application State")),

        // Developer tools
        additionalfeature(id: 231, title: "Xcode Project Health", detail: "Open Xcode's project support directory.", category: "Developer", icon: "hammer", action: .folder("~/Library/Developer/Xcode")),
        additionalfeature(id: 232, title: "Simulator Device Manager", detail: "Copy installed simulator device information.", category: "Developer", icon: "iphone.gen.3", action: .command("/usr/bin/xcrun", ["simctl", "list", "devices"])),
        additionalfeature(id: 233, title: "Simulator Data Cleaner", detail: "Open simulator data for targeted cleanup.", category: "Developer", icon: "iphone.and.arrow.forward", action: .folder("~/Library/Developer/CoreSimulator")),
        additionalfeature(id: 234, title: "DerivedData Dashboard", detail: "Open DerivedData for build cache review.", category: "Developer", icon: "hammer.fill", action: .folder("~/Library/Developer/Xcode/DerivedData")),
        additionalfeature(id: 235, title: "Code Signing Profile Viewer", detail: "Open local provisioning profiles.", category: "Developer", icon: "checkmark.seal", action: .folder("~/Library/MobileDevice/Provisioning Profiles")),
        additionalfeature(id: 236, title: "Provisioning Profile Inspector", detail: "Open provisioning profiles for inspection.", category: "Developer", icon: "doc.badge.gearshape", action: .folder("~/Library/MobileDevice/Provisioning Profiles")),
        additionalfeature(id: 237, title: "Developer Certificate Alerts", detail: "Copy installed signing identities.", category: "Developer", icon: "rosette", action: .command("/usr/bin/security", ["find-identity", "-v", "-p", "codesigning"])),
        additionalfeature(id: 238, title: "Local Git Repository Scanner", detail: "Open the home directory to choose a repository.", category: "Developer", icon: "arrow.triangle.pull", action: .folder("~")),
        additionalfeature(id: 239, title: "Uncommitted Changes Dashboard", detail: "Copy the current repository status.", category: "Developer", icon: "checklist", action: .command("/usr/bin/git", ["status", "--short"])),
        additionalfeature(id: 240, title: "Swift Package Cache Manager", detail: "Open Swift Package Manager caches.", category: "Developer", icon: "shippingbox", action: .folder("~/Library/Caches/org.swift.swiftpm")),

        // Package managers
        additionalfeature(id: 241, title: "Homebrew Health Repair", detail: "Copy Homebrew diagnostic output.", category: "Developer", icon: "heart.text.square", action: .command("/opt/homebrew/bin/brew", ["doctor"])),
        additionalfeature(id: 242, title: "Homebrew Dependency Graph", detail: "Copy installed Homebrew formulae.", category: "Developer", icon: "point.3.connected.trianglepath.dotted", action: .command("/opt/homebrew/bin/brew", ["list", "--formula"])),
        additionalfeature(id: 243, title: "Unused Homebrew Dependencies", detail: "Copy Homebrew leaves for review.", category: "Developer", icon: "shippingbox", action: .command("/opt/homebrew/bin/brew", ["leaves"])),
        additionalfeature(id: 244, title: "Homebrew Service Logs", detail: "Copy Homebrew service status.", category: "Developer", icon: "gearshape.2", action: .command("/opt/homebrew/bin/brew", ["services", "list"])),
        additionalfeature(id: 245, title: "npm Cache Health", detail: "Open the npm cache for inspection.", category: "Developer", icon: "shippingbox", action: .folder("~/.npm")),
        additionalfeature(id: 246, title: "pnpm Store Analyzer", detail: "Open the pnpm store location.", category: "Developer", icon: "shippingbox.fill", action: .folder("~/Library/pnpm")),
        additionalfeature(id: 247, title: "Yarn Cache Manager", detail: "Open the Yarn cache location.", category: "Developer", icon: "shippingbox.fill", action: .folder("~/Library/Caches/Yarn")),
        additionalfeature(id: 248, title: "Cargo Registry Cleaner", detail: "Open the Rust Cargo registry.", category: "Developer", icon: "shippingbox", action: .folder("~/.cargo/registry")),
        additionalfeature(id: 249, title: "pip Cache Cleaner", detail: "Open the Python cache location.", category: "Developer", icon: "shippingbox", action: .folder("~/Library/Caches/pip")),
        additionalfeature(id: 250, title: "Gem Cache Cleaner", detail: "Open Ruby gem support files.", category: "Developer", icon: "diamond", action: .folder("~/.gem")),

        // Networking
        additionalfeature(id: 251, title: "Network Quality History", detail: "Copy the active network interface summary.", category: "Network", icon: "waveform.path.ecg", action: .command("/sbin/ifconfig", [])),
        additionalfeature(id: 252, title: "Wi-Fi Channel Analyzer", detail: "Copy a Wi-Fi channel inspection hint.", category: "Network", icon: "wifi", action: .copy("Option-click the Wi-Fi menu to inspect channel details.")),
        additionalfeature(id: 253, title: "Wi-Fi Roaming Monitor", detail: "Copy active Wi-Fi network details.", category: "Network", icon: "wifi.router", action: .command("/usr/sbin/networksetup", ["-getinfo", "Wi-Fi"])),
        additionalfeature(id: 254, title: "DNS Latency Comparison", detail: "Copy DNS resolver configuration.", category: "Network", icon: "gauge.with.dots.needle.50percent", action: .command("/usr/sbin/scutil", ["--dns"])),
        additionalfeature(id: 255, title: "Local Network Device Map", detail: "Copy the local ARP device table.", category: "Network", icon: "network", action: .command("/usr/sbin/arp", ["-a"])),
        additionalfeature(id: 256, title: "Port Conflict Resolver", detail: "Copy listening TCP ports.", category: "Network", icon: "rectangle.connected.to.line.below", action: .command("/usr/sbin/lsof", ["-nP", "-iTCP", "-sTCP:LISTEN"])),
        additionalfeature(id: 257, title: "Network Route Visualizer", detail: "Copy the default network route.", category: "Network", icon: "arrow.triangle.branch", action: .command("/sbin/route", ["-n", "get", "default"])),
        additionalfeature(id: 258, title: "TCP Connection Monitor", detail: "Copy active network connections.", category: "Network", icon: "point.3.connected.trianglepath.dotted", action: .command("/usr/sbin/lsof", ["-nP", "-i"])),
        additionalfeature(id: 259, title: "Network Usage by Application", detail: "Copy Juicer network sockets.", category: "Network", icon: "chart.bar.xaxis", action: .command("/usr/sbin/lsof", ["-nP", "-i", "-a", "-c", "Juicer"])),
        additionalfeature(id: 260, title: "Captive Portal Detector", detail: "Open network settings to verify access.", category: "Network", icon: "globe", action: .settings("com.apple.preference.network")),

        // Privacy and security
        additionalfeature(id: 261, title: "Privacy Permission History", detail: "Open the privacy permission center.", category: "Privacy", icon: "clock.arrow.circlepath", action: .settings("com.apple.preference.security?Privacy")),
        additionalfeature(id: 262, title: "Camera Access History", detail: "Open camera privacy controls.", category: "Privacy", icon: "camera", action: .settings("com.apple.preference.security?Privacy_Camera")),
        additionalfeature(id: 263, title: "Microphone Access History", detail: "Open microphone privacy controls.", category: "Privacy", icon: "mic", action: .settings("com.apple.preference.security?Privacy_Microphone")),
        additionalfeature(id: 264, title: "Sensitive File Exposure Scan", detail: "Open Documents for review.", category: "Privacy", icon: "eye.slash", action: .folder("~/Documents")),
        additionalfeature(id: 265, title: "Public Wi-Fi Safety Check", detail: "Open Wi-Fi settings and review the active network.", category: "Privacy", icon: "wifi.exclamationmark", action: .settings("com.apple.wifi-settings-extension")),
        additionalfeature(id: 266, title: "Weak Password Policy Check", detail: "Open password and login security settings.", category: "Privacy", icon: "key", action: .settings("com.apple.Lock-Screen-Settings.extension")),
        additionalfeature(id: 267, title: "SSH Key Inventory", detail: "Open the local SSH directory.", category: "Developer", icon: "key.fill", action: .folder("~/.ssh")),
        additionalfeature(id: 268, title: "SSH Known Hosts Cleaner", detail: "Open known_hosts for targeted cleanup.", category: "Developer", icon: "person.2.badge.key", action: .folder("~/.ssh")),
        additionalfeature(id: 269, title: "Environment Secret Scanner", detail: "Copy environment variable names only.", category: "Privacy", icon: "key.viewfinder", action: .command("/bin/sh", ["-c", "env | cut -d= -f1 | sort"])),
        additionalfeature(id: 270, title: "Git Secret Detection Starter", detail: "Open the home directory to select a repository.", category: "Privacy", icon: "magnifyingglass", action: .folder("~")),

        // Automation and productivity
        additionalfeature(id: 271, title: "Scheduled Maintenance Workflows", detail: "Copy a Workflow Center scheduling reminder.", category: "System", icon: "calendar.badge.clock", action: .copy("Open Workflow Center to schedule a maintenance recipe.")),
        additionalfeature(id: 272, title: "Conditional Automation Triggers", detail: "Copy a disk-usage workflow condition.", category: "Developer", icon: "arrow.triangle.branch", action: .copy("condition: disk usage > 88%; action: run storage diagnostics")),
        additionalfeature(id: 273, title: "Battery-Aware Automation", detail: "Copy a battery-aware workflow condition.", category: "Hardware", icon: "battery.50percent", action: .copy("condition: on battery; action: reduce background checks")),
        additionalfeature(id: 274, title: "Network-Aware Automation", detail: "Copy a network-aware workflow condition.", category: "Network", icon: "network", action: .copy("condition: trusted network; action: enable network diagnostics")),
        additionalfeature(id: 275, title: "Focus Mode Automation", detail: "Open Focus settings for workflow pairing.", category: "System", icon: "moon", action: .settings("com.apple.Focus")),
        additionalfeature(id: 276, title: "App Launch Automation", detail: "Copy a launch-trigger workflow template.", category: "Developer", icon: "play.circle", action: .copy("trigger: application launched; action: run workflow")),
        additionalfeature(id: 277, title: "Folder Watch Automation", detail: "Copy a folder-trigger workflow template.", category: "Files", icon: "folder.badge.plus", action: .copy("trigger: folder changed; action: run workflow")),
        additionalfeature(id: 278, title: "Shortcuts Integration Starter", detail: "Open macOS Shortcuts settings.", category: "Accessibility", icon: "command", action: .settings("com.apple.shortcuts")),
        additionalfeature(id: 279, title: "AppleScript Workflow Template", detail: "Copy a safe AppleScript starter.", category: "Developer", icon: "applescript", action: .copy("tell application \"Finder\" to display dialog \"Juicer workflow\"")),
        additionalfeature(id: 280, title: "Shell Approval Profile", detail: "Copy a read-only command policy template.", category: "Privacy", icon: "checkmark.shield", action: .copy("allowed: read-only diagnostics; approval required: writes and deletion")),

        // Monitoring
        additionalfeature(id: 281, title: "CPU Temperature History", detail: "Copy thermal readings when available.", category: "Hardware", icon: "thermometer.medium", action: .command("/usr/bin/pmset", ["-g", "therm"])),
        additionalfeature(id: 282, title: "GPU Usage History", detail: "Copy current process activity.", category: "Hardware", icon: "display.2", action: .command("/usr/bin/top", ["-l", "1", "-stats", "pid,command,cpu"])),
        additionalfeature(id: 283, title: "Fan Speed Monitor", detail: "Copy available power and thermal information.", category: "Hardware", icon: "fanblades.fill", action: .command("/usr/bin/pmset", ["-g", "therm"])),
        additionalfeature(id: 284, title: "Battery Health History", detail: "Copy battery health and cycle information.", category: "Hardware", icon: "battery.100", action: .command("/usr/bin/pmset", ["-g", "batt"])),
        additionalfeature(id: 285, title: "Power Adapter Diagnostics", detail: "Copy power source diagnostics.", category: "Hardware", icon: "powerplug", action: .command("/usr/bin/pmset", ["-g", "ps"])),
        additionalfeature(id: 286, title: "Memory Pressure Alerts", detail: "Copy current virtual-memory statistics.", category: "Hardware", icon: "memorychip", action: .command("/usr/bin/vm_stat", [])),
        additionalfeature(id: 287, title: "Process Resource Ranking", detail: "Copy the top CPU processes.", category: "System", icon: "chart.bar", action: .command("/usr/bin/top", ["-l", "1", "-o", "cpu"])),
        additionalfeature(id: 288, title: "Thermal Throttling Detector", detail: "Copy thermal pressure information.", category: "Hardware", icon: "thermometer.sun", action: .command("/usr/bin/pmset", ["-g", "therm"])),
        additionalfeature(id: 289, title: "Disk Health Notifications", detail: "Copy disk and volume information.", category: "Files", icon: "externaldrive.badge.checkmark", action: .command("/usr/sbin/diskutil", ["list"])),
        additionalfeature(id: 290, title: "Network Outage Notifications", detail: "Copy the default route state.", category: "Network", icon: "wifi.exclamationmark", action: .command("/sbin/route", ["-n", "get", "default"])),

        // Interface and productivity
        additionalfeature(id: 291, title: "Universal Quick Action Search", detail: "Copy the command palette shortcut.", category: "Accessibility", icon: "magnifyingglass", action: .copy("Use Command-K to open Juicer's command palette.")),
        additionalfeature(id: 292, title: "Custom Dashboard Widgets", detail: "Copy a dashboard customization reminder.", category: "System", icon: "square.grid.2x2", action: .copy("Customize the Juicer Hub dashboard from its layout controls.")),
        additionalfeature(id: 293, title: "Dashboard Layout Presets", detail: "Copy a compact dashboard preset.", category: "System", icon: "rectangle.3.group", action: .copy("preset: compact; density: comfortable; sidebar: visible")),
        additionalfeature(id: 294, title: "Tool Pinning and Grouping", detail: "Copy instructions for favoriting tools.", category: "Accessibility", icon: "pin", action: .copy("Use the star beside a tool to pin it to Favorites.")),
        additionalfeature(id: 295, title: "Recently Used Tools Timeline", detail: "Copy an Action History reminder.", category: "System", icon: "clock.arrow.circlepath", action: .copy("Open Action History to review recently used tools.")),
        additionalfeature(id: 296, title: "Keyboard Shortcut Editor", detail: "Open macOS keyboard shortcut settings.", category: "Accessibility", icon: "keyboard", action: .settings("com.apple.preference.keyboard")),
        additionalfeature(id: 297, title: "Multi-Window Workspace Guide", detail: "Copy a workspace navigation guide.", category: "Accessibility", icon: "macwindow.on.rectangle", action: .copy("Use the workspace hub to switch between focused tool studios.")),
        additionalfeature(id: 298, title: "Compact Floating Inspector", detail: "Copy a compact inspector layout.", category: "Accessibility", icon: "rectangle.righthalf.inset.filled", action: .copy("layout: compact; details: on; sidebar: narrow")),
        additionalfeature(id: 299, title: "Menu Bar Summary Settings", detail: "Open Control Center settings.", category: "System", icon: "menubar.rectangle", action: .settings("com.apple.ControlCenter")),
        additionalfeature(id: 300, title: "Export Personal Juicer Profile", detail: "Copy a settings export reminder.", category: "Files", icon: "square.and.arrow.up", action: .copy("Use Settings > Control Center > Export Settings to save a Juicer profile."))
    ]
}
