import SwiftUI
import AppKit

private struct additionalfeature: Identifiable {
    enum action {
        case settings(String)
        case folder(String)
        case copy(String)
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
        additionalfeature(id: 200, title: "Open Juicer Preferences", detail: "Open Juicer's own settings window.", category: "System", icon: "gearshape.2", action: .settings("com.even.juicer"))
    ]
}
