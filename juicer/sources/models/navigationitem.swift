enum JuicerWorkspace: String, CaseIterable, Identifiable {
    case hub = "Juicer Hub"
    case store = "Juicer Store"
    case system = "Juicer System"
    case disk = "Juicer Disk"
    case configs = "Juicer Configs"
    case utilities = "Juicer Utilities"
    
    var id: String { rawValue }
    
    var title: String { rawValue }
    
    var description: String {
        switch self {
        case .hub: return "The home launcher dashboard."
        case .store: return "Browse Homebrew casks and formulae repositories, install applications, and trigger software updates."
        case .system: return "Inspect system metrics, manage active processes, trace DNS configs, and run shell automations."
        case .disk: return "Drill down drive directories, clean developer/app caches, and manage rollback history."
        case .configs: return "Uninstall applications, find orphaned folders, edit launch agents, and toggle hidden macOS settings."
        case .utilities: return "Enable active window switchers, clipboard tracking lists, window snaps, color loupes, and note pads."
        }
    }
}

enum NavigationItem: String, CaseIterable, Identifiable {
    case dashboard
    case appUninstaller
    case orphanScanner
    case serviceManager
    case devCaches
    case systemTweaks
    case quarantineStripper
    case dnsEditor
    case launchServices
    case hiddenFiles
    case appLipo
    case largeFiles
    case brewExplorer
    case sdkSwitcher
    case portListener
    case diskExplorer
    case systemOptimizer
    case statusMonitor
    case cacheCleaner
    case appStore
    case snapshots
    case scriptConsole
    case utilitiesView
    case diskVisualizer
    case undoHistory
    case appUpdates
    case tccViewer
    case cpuMemoryMonitor, gpuMonitor, diskIOMonitor, networkTraffic, batteryHealth, startupItems, loginItemDelays, processKiller, systemLogs, kextManager, powerSchedule, thermalMonitor, fanController, memoryPurge, swapManager, vpnProfiles, networkLocations, bluetoothDevices, airDropQuickSend, duplicateFiles, emptyFolders, downloadOrganizer, archiveUtility, diskImages, permissionRepair, extendedAttributes, fileTypeConverter, metadataEditor, symbolicLinks, diskVerification, storageSnapshots, fileVault, firewall, privacyScanner, passwordAudit, secureDelete, quarantinedFiles, sandboxInspector, networkExposure, usbDeviceGuard, screenRecording, clipboardAccess, locationServices, microphoneCamera, antiKeylogger, secureNotes, clipboardManager, snippetExpander, menuBarCustomizer, desktopIcons, hotCorners, keyboardShortcuts, textCaseConverter, characterCounter, qrCode, colorPicker, screenRuler, screenLoupe, batterySaver, printerQueue, pdfToolbox, markdownPreviewer, codeSnippets, localWebServer, portScanner, lanDiscovery, wifiSurvey, networkProfileSwitcher, vpnAutoConnect, publicIP, speedTest, dnsDiagnostics, hostsFile, blocklistUpdater, appLocker, fileVaultAutoLock, japaneseKana
    
    var id: NavigationItem { self }
    
    var workspace: JuicerWorkspace {
        switch self {
        case .appStore, .brewExplorer, .appUpdates:
            return .store
        case .dashboard, .statusMonitor, .portListener, .scriptConsole, .snapshots, .cpuMemoryMonitor, .gpuMonitor, .diskIOMonitor, .networkTraffic, .batteryHealth, .startupItems, .loginItemDelays, .processKiller, .systemLogs, .kextManager, .powerSchedule, .thermalMonitor, .fanController, .memoryPurge, .swapManager, .vpnProfiles, .networkLocations, .bluetoothDevices, .airDropQuickSend, .fileVault, .firewall, .networkExposure, .usbDeviceGuard, .screenRecording, .clipboardAccess, .locationServices, .microphoneCamera:
            return .system
        case .diskExplorer, .cacheCleaner, .devCaches, .largeFiles, .hiddenFiles, .diskVisualizer, .undoHistory, .duplicateFiles, .emptyFolders, .downloadOrganizer, .archiveUtility, .diskImages, .fileTypeConverter, .symbolicLinks, .diskVerification, .storageSnapshots, .secureDelete:
            return .disk
        case .appUninstaller, .orphanScanner, .appLipo, .serviceManager, .systemTweaks, .quarantineStripper, .dnsEditor, .launchServices, .sdkSwitcher, .systemOptimizer, .tccViewer, .permissionRepair, .extendedAttributes, .metadataEditor, .privacyScanner, .passwordAudit, .quarantinedFiles, .sandboxInspector, .antiKeylogger, .secureNotes:
            return .configs
        case .utilitiesView, .clipboardManager, .snippetExpander, .menuBarCustomizer, .desktopIcons, .hotCorners, .keyboardShortcuts, .textCaseConverter, .characterCounter, .qrCode, .colorPicker, .screenRuler, .screenLoupe, .batterySaver, .printerQueue, .pdfToolbox, .markdownPreviewer, .codeSnippets, .localWebServer, .portScanner, .lanDiscovery, .wifiSurvey, .networkProfileSwitcher, .vpnAutoConnect, .publicIP, .speedTest, .dnsDiagnostics, .hostsFile, .blocklistUpdater, .appLocker, .fileVaultAutoLock, .japaneseKana:
            return .utilities
        }
    }
    
    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .appUninstaller: return "App Uninstaller"
        case .orphanScanner: return "Orphan Finder"
        case .serviceManager: return "Service Manager"
        case .devCaches: return "Developer Caches"
        case .systemTweaks: return "System Tweaks"
        case .quarantineStripper: return "Quarantine Stripper"
        case .dnsEditor: return "DNS Editor"
        case .launchServices: return "File Associations"
        case .hiddenFiles: return "Hidden File Explorer"
        case .appLipo: return "App Lipo Slicer"
        case .largeFiles: return "Large & Old Files"
        case .brewExplorer: return "Homebrew Explorer"
        case .sdkSwitcher: return "SDK & Runtime Switcher"
        case .portListener: return "Port Listener"
        case .diskExplorer: return "Disk Explorer"
        case .systemOptimizer: return "System Optimizer"
        case .statusMonitor: return "Live Status"
        case .cacheCleaner: return "Cache Cleaner"
        case .appStore: return "Software Center"
        case .snapshots: return "Diagnostic Snapshots"
        case .scriptConsole: return "Script Console"
        case .utilitiesView: return "Utilities Settings"
        case .diskVisualizer: return "Disk Visualizer"
        case .undoHistory: return "Undo Deletion History"
        case .appUpdates: return "Package Upgrades"
        case .tccViewer: return "Privacy Cabinet"
        case .cpuMemoryMonitor: return "CPU & Memory Monitor"
        case .gpuMonitor: return "GPU Utilization Monitor"
        case .diskIOMonitor: return "Disk I/O Monitor"
        case .networkTraffic: return "Network Traffic Monitor"
        case .batteryHealth: return "Battery Health Dashboard"
        case .startupItems: return "Startup Item Manager"
        case .loginItemDelays: return "Login Item Delays"
        case .processKiller: return "Process Killer"
        case .systemLogs: return "System Log Viewer"
        case .kextManager: return "KEXT Manager"
        case .powerSchedule: return "Power Schedule"
        case .thermalMonitor: return "Thermal Monitor"
        case .fanController: return "Fan Controller"
        case .memoryPurge: return "RAM Cleaner"
        case .swapManager: return "Swap Manager"
        case .vpnProfiles: return "VPN Profiles"
        case .networkLocations: return "Network Locations"
        case .bluetoothDevices: return "Bluetooth Devices"
        case .airDropQuickSend: return "AirDrop Quick-Send"
        case .duplicateFiles: return "Duplicate Files"
        case .emptyFolders: return "Empty Folders"
        case .downloadOrganizer: return "Download Organizer"
        case .archiveUtility: return "Archive Utility"
        case .diskImages: return "Disk Image Manager"
        case .permissionRepair: return "Permissions Repair"
        case .extendedAttributes: return "Extended Attributes"
        case .fileTypeConverter: return "File Type Converter"
        case .metadataEditor: return "Metadata Editor"
        case .symbolicLinks: return "Symbolic Link Manager"
        case .diskVerification: return "Disk Verification & Repair"
        case .storageSnapshots: return "Storage Snapshot Manager"
        case .fileVault: return "FileVault Status"
        case .firewall: return "Firewall Configuration"
        case .privacyScanner: return "Privacy Scanner"
        case .passwordAudit: return "Password Audit"
        case .secureDelete: return "Secure Delete"
        case .quarantinedFiles: return "Quarantined-file Scanner"
        case .sandboxInspector: return "Application Sandbox Inspector"
        case .networkExposure: return "Network Exposure Monitor"
        case .usbDeviceGuard: return "USB Device Guard"
        case .screenRecording: return "Screen Recording Detector"
        case .clipboardAccess: return "Clipboard Access Monitor"
        case .locationServices: return "Location Services Auditor"
        case .microphoneCamera: return "Microphone & Camera Indicator"
        case .antiKeylogger: return "Anti-Keylogger Scanner"
        case .secureNotes: return "Secure Notes Vault"
        case .clipboardManager: return "Clipboard Manager"
        case .snippetExpander: return "Snippet Expander"
        case .menuBarCustomizer: return "Menu-Bar Customizer"
        case .desktopIcons: return "Desktop Icons Toggle"
        case .hotCorners: return "Hot Corners Configurator"
        case .keyboardShortcuts: return "Keyboard Shortcut Manager"
        case .textCaseConverter: return "Text Case Converter"
        case .characterCounter: return "Character & Word Counter"
        case .qrCode: return "QR Code Generator"
        case .colorPicker: return "Color Picker"
        case .screenRuler: return "Screen Ruler & Protractor"
        case .screenLoupe: return "Pixel-Perfect Screen Loupe"
        case .batterySaver: return "Battery-Saver Mode"
        case .printerQueue: return "Printer Queue Manager"
        case .pdfToolbox: return "PDF Toolbox"
        case .markdownPreviewer: return "Markdown Previewer"
        case .codeSnippets: return "Code Snippets Library"
        case .localWebServer: return "Local Web Server"
        case .portScanner: return "Port Scanner"
        case .lanDiscovery: return "LAN Device Discovery"
        case .wifiSurvey: return "Wi-Fi Survey Tool"
        case .networkProfileSwitcher: return "Network-Profile Switcher"
        case .vpnAutoConnect: return "VPN Auto-Connect"
        case .publicIP: return "Public IP & Geoloc Lookup"
        case .speedTest: return "Speed Test Tool"
        case .dnsDiagnostics: return "DNS Resolver Diagnostics"
        case .hostsFile: return "Hosts File Editor"
        case .blocklistUpdater: return "Ad-block List Updater"
        case .appLocker: return "App Locker"
        case .fileVaultAutoLock: return "File Vault Auto-Lock"
        case .japaneseKana: return "Japanese & Kana Helper"
        }
    }
    
    var iconName: String {
        switch self {
        case .dashboard: return "house.fill"
        case .appUninstaller: return "trash.fill"
        case .orphanScanner: return "folder.badge.minus"
        case .serviceManager: return "cpu"
        case .devCaches: return "hammer.fill"
        case .systemTweaks: return "slider.horizontal.3"
        case .quarantineStripper: return "shield.slash.fill"
        case .dnsEditor: return "network"
        case .launchServices: return "doc.badge.gearshape.fill"
        case .hiddenFiles: return "eye.slash.fill"
        case .appLipo: return "cpu.fill"
        case .largeFiles: return "doc.badge.ellipsis"
        case .brewExplorer: return "shippingbox.fill"
        case .sdkSwitcher: return "square.stack.3d.up.fill"
        case .portListener: return "network.badge.shield.half.filled"
        case .diskExplorer: return "internaldrive.fill"
        case .systemOptimizer: return "bolt.fill"
        case .statusMonitor: return "waveform.path.ecg"
        case .cacheCleaner: return "sparkle.magnifyingglass"
        case .appStore: return "square.grid.3x3.fill"
        case .snapshots: return "camera.viewfinder"
        case .scriptConsole: return "terminal.fill"
        case .utilitiesView: return "wrench.and.screwdriver.fill"
        case .diskVisualizer: return "chart.pie.fill"
        case .undoHistory: return "clock.arrow.circlepath"
        case .appUpdates: return "arrow.triangle.2.circlepath.circle.fill"
        case .tccViewer: return "shield.fill"
        case .cpuMemoryMonitor: return "waveform.path.ecg"
        case .gpuMonitor: return "display.2"
        case .diskIOMonitor: return "internaldrive"
        case .networkTraffic: return "network"
        case .batteryHealth: return "battery.100"
        case .startupItems: return "arrow.up.forward.app"
        case .loginItemDelays: return "timer"
        case .processKiller: return "xmark.octagon"
        case .systemLogs: return "doc.text.magnifyingglass"
        case .kextManager: return "puzzlepiece.extension"
        case .powerSchedule: return "calendar.badge.clock"
        case .thermalMonitor: return "thermometer.medium"
        case .fanController: return "fanblades.fill"
        case .memoryPurge: return "memorychip"
        case .swapManager: return "arrow.left.arrow.right"
        case .vpnProfiles: return "lock.shield"
        case .networkLocations: return "network"
        case .bluetoothDevices: return "dot.radiowaves.left.and.right"
        case .airDropQuickSend: return "airplayaudio"
        case .duplicateFiles: return "doc.on.doc"
        case .emptyFolders: return "folder.badge.minus"
        case .downloadOrganizer: return "folder.badge.gearshape"
        case .archiveUtility: return "archivebox"
        case .diskImages: return "externaldrive.badge.timemachine"
        case .permissionRepair: return "lock.document"
        case .extendedAttributes: return "tag"
        case .fileTypeConverter: return "arrow.triangle.2.circlepath"
        case .metadataEditor: return "tag.fill"
        case .symbolicLinks: return "link"
        case .diskVerification: return "checkmark.shield"
        case .storageSnapshots: return "clock.arrow.circlepath"
        case .fileVault: return "lock.shield"
        case .firewall: return "flame"
        case .privacyScanner: return "hand.raised.shield"
        case .passwordAudit: return "key.fill"
        case .secureDelete: return "trash.slash"
        case .quarantinedFiles: return "shield.lefthalf.filled"
        case .sandboxInspector: return "shippingbox"
        case .networkExposure: return "network.badge.shield.half.filled"
        case .usbDeviceGuard: return "externaldrive.connected.to.line.below"
        case .screenRecording: return "record.circle"
        case .clipboardAccess: return "doc.on.clipboard"
        case .locationServices: return "location.fill"
        case .microphoneCamera: return "mic.and.signal.meter"
        case .antiKeylogger: return "keyboard.badge.ellipsis"
        case .secureNotes: return "note.text.badge.lock"
        case .clipboardManager: return "doc.on.clipboard.fill"
        case .snippetExpander: return "text.badge.plus"
        case .menuBarCustomizer: return "menubar.rectangle"
        case .desktopIcons: return "macwindow"
        case .hotCorners: return "rectangle.4.connected.lines"
        case .keyboardShortcuts: return "keyboard"
        case .textCaseConverter: return "textformat"
        case .characterCounter: return "number"
        case .qrCode: return "qrcode"
        case .colorPicker: return "eyedropper.halffull"
        case .screenRuler: return "ruler"
        case .screenLoupe: return "magnifyingglass"
        case .batterySaver: return "battery.50percent"
        case .printerQueue: return "printer"
        case .pdfToolbox: return "doc.richtext"
        case .markdownPreviewer: return "doc.text"
        case .codeSnippets: return "curlybraces.square"
        case .localWebServer: return "server.rack"
        case .portScanner: return "dot.radiowaves.left.and.right"
        case .lanDiscovery: return "network"
        case .wifiSurvey: return "wifi"
        case .networkProfileSwitcher: return "network"
        case .vpnAutoConnect: return "lock.shield"
        case .publicIP: return "globe"
        case .speedTest: return "speedometer"
        case .dnsDiagnostics: return "network.badge.shield.half.filled"
        case .hostsFile: return "list.bullet.rectangle"
        case .blocklistUpdater: return "shield.checkered"
        case .appLocker: return "lock.app.dashed"
        case .fileVaultAutoLock: return "lock.display"
        case .japaneseKana: return "character.book.closed"
        }
    }
}
