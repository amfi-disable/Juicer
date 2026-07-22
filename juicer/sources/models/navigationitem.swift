import SwiftUI

enum JuicerWorkspace: String, CaseIterable, Identifiable {
    case hub = "Juicer Hub Studio"
    case store = "Juicer Store Studio"
    case system = "Juicer System Studio"
    case network = "Juicer Network Studio"
    case security = "Juicer Security Studio"
    case disk = "Juicer Disk Studio"
    case developer = "Juicer Developer Studio"
    case git = "Juicer Git Studio"
    case configs = "Juicer Configs Studio"
    case utilities = "Juicer Utilities Studio"
    
    var id: String { rawValue }
    
    var title: String { rawValue }
    
    var iconName: String {
        switch self {
        case .hub: return "square.grid.2x2.fill"
        case .store: return "shippingbox.fill"
        case .system: return "cpu.fill"
        case .network: return "network"
        case .security: return "lock.shield.fill"
        case .disk: return "internaldrive.fill"
        case .developer: return "terminal.fill"
        case .git: return "arrow.triangle.pull"
        case .configs: return "slider.horizontal.3"
        case .utilities: return "wrench.and.screwdriver.fill"
        }
    }
    
    var description: String {
        switch self {
        case .hub: return "Central launchpad canvas and workspace navigator."
        case .store: return "Homebrew casks, formula repositories, and app updates."
        case .system: return "CPU, GPU, memory gauges, battery, power, and thermal monitor."
        case .network: return "Network speed test, Wi-Fi survey, port listener, and DNS."
        case .security: return "TCC permissions audit, privacy cabinet, FileVault, and app lock."
        case .disk: return "Space Lens visualizer, dev cache cleaner, and duplicate finder."
        case .developer: return "SDK runtimes, script plugins, local web server, and snippets."
        case .git: return "Git repository workbench, commit graph, and analytics."
        case .configs: return "App uninstaller, launch daemons, and system tweaks."
        case .utilities: return "Window tiler, clipboard manager, hot corners, and desktop tools."
        }
    }
    
    var themeColor: Color {
        switch self {
        case .hub: return .orange
        case .store: return .cyan
        case .system: return .blue
        case .network: return .teal
        case .security: return .red
        case .disk: return .orange
        case .developer: return .green
        case .git: return .purple
        case .configs: return .indigo
        case .utilities: return .gray
        }
    }
}

enum NavigationItem: String, CaseIterable, Identifiable, Equatable {
    case dashboard, workflowCenter
    case featureCatalog
    case actionHistory
    case permissionCenter
    case scriptPlugins
    case appUninstaller, orphanScanner, brewGhost, serviceManager
    case devCaches, systemTweaks, quarantineStripper, dnsEditor
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
    case envProfiles
    case appLanguageStripper
    case ocrScreenGrabber
    case logStream
    case nlToCommand
    case imageConverter
    case juicerGit
    case gitExtras
    case snapshots
    case scriptConsole
    case utilitiesView
    case diskVisualizer
    case undoHistory
    case appUpdates
    case tccViewer
    case creatorRepos
    case cpuMemoryMonitor, gpuMonitor, diskIOMonitor, networkTraffic, batteryHealth, startupItems, loginItemDelays, processKiller, systemLogs, kextManager, powerSchedule, thermalMonitor, fanController, memoryPurge, swapManager, vpnProfiles, networkLocations, bluetoothDevices, airDropQuickSend, duplicateFiles, emptyFolders, downloadOrganizer, archiveUtility, diskImages, permissionRepair, extendedAttributes, fileTypeConverter, metadataEditor, symbolicLinks, diskVerification, storageSnapshots, fileVault, firewall, privacyScanner, passwordAudit, secureDelete, quarantinedFiles, sandboxInspector, networkExposure, usbDeviceGuard, screenRecording, clipboardAccess, locationServices, microphoneCamera, antiKeylogger, secureNotes, clipboardManager, snippetExpander, menuBarCustomizer, desktopIcons, hotCorners, keyboardShortcuts, textCaseConverter, characterCounter, qrCode, colorPicker, screenRuler, screenLoupe, batterySaver, printerQueue, pdfToolbox, markdownPreviewer, codeSnippets, localWebServer, portScanner, lanDiscovery, wifiSurvey, networkProfileSwitcher, vpnAutoConnect, publicIP, speedTest, dnsDiagnostics, hostsFile, blocklistUpdater, appLocker, fileVaultAutoLock, japaneseKana, emojiPicker, unicodeInspector, screenshotAnnotation, windowSnapping, displayProfiles, nightShift, keyboardBacklight, trackpadGestures, shortcutRunner, systemInfoExporter, softwareInventory, autoUpdateChecker, logRotator, systemServices, diskSpacePredictor, backupTrigger, networkLimiter, diskImageMounter, soundVolumeMixer
    
    var id: NavigationItem { self }
    
    var workspace: JuicerWorkspace {
        switch self {
        case .juicerGit, .gitExtras:
            return .git
        case .appStore, .brewExplorer, .appUpdates, .creatorRepos:
            return .store
        case .dashboard, .workflowCenter, .statusMonitor, .cpuMemoryMonitor, .gpuMonitor, .diskIOMonitor, .batteryHealth, .powerSchedule, .thermalMonitor, .fanController, .memoryPurge, .swapManager, .batterySaver, .kextManager, .startupItems, .loginItemDelays, .processKiller, .systemLogs, .systemServices:
            return .system
        case .networkTraffic, .portListener, .vpnProfiles, .networkLocations, .bluetoothDevices, .airDropQuickSend, .portScanner, .lanDiscovery, .wifiSurvey, .networkProfileSwitcher, .vpnAutoConnect, .publicIP, .speedTest, .dnsDiagnostics, .hostsFile, .blocklistUpdater, .firewall, .networkExposure, .networkLimiter:
            return .network
        case .tccViewer, .fileVault, .privacyScanner, .passwordAudit, .secureDelete, .quarantinedFiles, .sandboxInspector, .usbDeviceGuard, .screenRecording, .clipboardAccess, .locationServices, .microphoneCamera, .antiKeylogger, .secureNotes, .appLocker, .fileVaultAutoLock, .permissionCenter:
            return .security
        case .diskExplorer, .cacheCleaner, .devCaches, .largeFiles, .hiddenFiles, .diskVisualizer, .undoHistory, .duplicateFiles, .emptyFolders, .downloadOrganizer, .archiveUtility, .diskImages, .fileTypeConverter, .symbolicLinks, .diskVerification, .storageSnapshots, .diskSpacePredictor, .backupTrigger, .diskImageMounter:
            return .disk
        case .sdkSwitcher, .scriptPlugins, .envProfiles, .appLanguageStripper, .ocrScreenGrabber, .logStream, .nlToCommand, .imageConverter, .scriptConsole, .codeSnippets, .localWebServer:
            return .developer
        case .appUninstaller, .orphanScanner, .brewGhost, .appLipo, .serviceManager, .systemTweaks, .quarantineStripper, .dnsEditor, .launchServices, .systemOptimizer, .permissionRepair, .extendedAttributes, .metadataEditor, .autoUpdateChecker, .logRotator:
            return .configs
        case .featureCatalog, .actionHistory, .utilitiesView, .clipboardManager, .snippetExpander, .menuBarCustomizer, .desktopIcons, .hotCorners, .keyboardShortcuts, .textCaseConverter, .characterCounter, .qrCode, .colorPicker, .screenRuler, .screenLoupe, .printerQueue, .pdfToolbox, .markdownPreviewer, .japaneseKana, .emojiPicker, .unicodeInspector, .screenshotAnnotation, .windowSnapping, .displayProfiles, .nightShift, .keyboardBacklight, .trackpadGestures, .shortcutRunner, .systemInfoExporter, .softwareInventory, .snapshots, .soundVolumeMixer:
            return .utilities
        }
    }
    
    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .workflowCenter: return "Workflow Center"
        case .featureCatalog: return "Additional Features"
        case .actionHistory: return "Action History"
        case .permissionCenter: return "Permission Center"
        case .scriptPlugins: return "Script Plugins"
        case .appUninstaller: return "App Uninstaller"
        case .orphanScanner: return "Orphan Finder"
        case .brewGhost: return "Brew-Ghost Companion"
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
        case .creatorRepos: return "Creator Repositories"
        case .envProfiles: return "Env Profiles & Secrets"
        case .appLanguageStripper: return "App Language Stripper"
        case .ocrScreenGrabber: return "OCR Screen Grabber"
        case .logStream: return "Unified Log Stream"
        case .nlToCommand: return "Natural Language Command Generator"
        case .imageConverter: return "Batch Image Converter"
        case .juicerGit: return "Git Studio & Workbench"
        case .gitExtras: return "Git Analytics & Power Tools"
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
        case .emojiPicker: return "Emoji Picker"
        case .unicodeInspector: return "Unicode Character Inspector"
        case .screenshotAnnotation: return "Screenshot Annotation Tool"
        case .windowSnapping: return "Window-Snapping & Tiling"
        case .displayProfiles: return "Display Profile Manager"
        case .nightShift: return "Night Shift & True Tone Scheduler"
        case .keyboardBacklight: return "Keyboard Backlight Timer"
        case .trackpadGestures: return "Trackpad Gesture Customizer"
        case .shortcutRunner: return "Automator & Shortcut Runner"
        case .systemInfoExporter: return "System Info Exporter"
        case .softwareInventory: return "License & Software Inventory"
        case .autoUpdateChecker: return "Auto-Update Checker"
        case .logRotator: return "Log File Rotator"
        case .systemServices: return "System Service Status"
        case .diskSpacePredictor: return "Disk Space Predictor"
        case .backupTrigger: return "Automatic Backup Trigger"
        case .networkLimiter: return "Network Speed Limiter"
        case .diskImageMounter: return "Automatic Disk Image Mounter"
        case .soundVolumeMixer: return "Sound Volume Mixer"
        }
    }
    
    var iconName: String {
        switch self {
        case .dashboard: return "house.fill"
        case .workflowCenter: return "list.bullet.clipboard"
        case .featureCatalog: return "square.grid.2x2"
        case .actionHistory: return "clock.arrow.circlepath"
        case .permissionCenter: return "lock.shield"
        case .scriptPlugins: return "puzzlepiece.extension"
        case .appUninstaller: return "trash.fill"
        case .orphanScanner: return "folder.badge.minus"
        case .brewGhost: return "ghost.fill"
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
        case .creatorRepos: return "star.square.on.square.fill"
        case .envProfiles: return "slider.horizontal.3"
        case .appLanguageStripper: return "globe"
        case .ocrScreenGrabber: return "viewfinder"
        case .logStream: return "doc.text.magnifyingglass"
        case .nlToCommand: return "terminal"
        case .imageConverter: return "photo.stack"
        case .juicerGit: return "arrow.triangle.pull"
        case .gitExtras: return "chart.bar.doc.horizontal.fill"
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
        case .emojiPicker: return "face.smiling"
        case .unicodeInspector: return "character"
        case .screenshotAnnotation: return "pencil.and.outline"
        case .windowSnapping: return "rectangle.split.2x1"
        case .displayProfiles: return "display.2"
        case .nightShift: return "sun.horizon"
        case .keyboardBacklight: return "light.min"
        case .trackpadGestures: return "hand.draw"
        case .shortcutRunner: return "command"
        case .systemInfoExporter: return "doc.badge.gearshape"
        case .softwareInventory: return "shippingbox"
        case .autoUpdateChecker: return "arrow.triangle.2.circlepath"
        case .logRotator: return "doc.zipper"
        case .systemServices: return "gearshape.2"
        case .diskSpacePredictor: return "chart.line.uptrend.xyaxis"
        case .backupTrigger: return "externaldrive.badge.timemachine"
        case .networkLimiter: return "gauge.with.dots.needle.33percent"
        case .diskImageMounter: return "externaldrive.badge.plus"
        case .soundVolumeMixer: return "speaker.wave.2"
        }
    }
    
    var subcategory: String {
        switch self {
        // System & Hardware
        case .dashboard, .statusMonitor, .cpuMemoryMonitor, .gpuMonitor, .diskIOMonitor:
            return "Monitoring & Gauges"
        case .batteryHealth, .batterySaver, .powerSchedule, .thermalMonitor, .fanController, .memoryPurge, .swapManager:
            return "Hardware & Power"
        case .processKiller, .startupItems, .loginItemDelays, .systemLogs, .systemServices, .kextManager, .workflowCenter:
            return "Process & System Logs"
            
        // Network & Ports
        case .speedTest, .networkTraffic, .publicIP, .networkLimiter:
            return "Speed & Traffic"
        case .wifiSurvey, .lanDiscovery, .portScanner, .portListener, .dnsDiagnostics:
            return "Diagnostics & Ports"
        case .firewall, .vpnProfiles, .vpnAutoConnect, .networkExposure, .hostsFile, .blocklistUpdater, .networkLocations, .bluetoothDevices, .airDropQuickSend, .networkProfileSwitcher:
            return "Firewall & Security"
            
        // Security & Privacy
        case .tccViewer, .privacyScanner, .locationServices, .clipboardAccess, .microphoneCamera, .screenRecording:
            return "Privacy & Permissions"
        case .fileVault, .fileVaultAutoLock, .secureNotes, .appLocker, .passwordAudit, .secureDelete:
            return "Vault & Encryption"
        case .antiKeylogger, .quarantinedFiles, .sandboxInspector, .usbDeviceGuard, .permissionCenter:
            return "System Defense"
            
        // Disk & Storage
        case .diskExplorer, .diskVisualizer, .storageSnapshots, .diskVerification, .diskImageMounter:
            return "Explorers & Visualizers"
        case .cacheCleaner, .devCaches, .largeFiles, .duplicateFiles, .emptyFolders:
            return "Cleaners & Large Files"
        case .undoHistory, .downloadOrganizer, .archiveUtility, .diskImages, .fileTypeConverter, .symbolicLinks, .diskSpacePredictor, .backupTrigger:
            return "File Utilities"
            
        // Git Studio
        case .juicerGit, .gitExtras:
            return "Git Tools & Workbench"
            
        // Developer Suite
        case .sdkSwitcher, .scriptPlugins, .scriptConsole, .localWebServer:
            return "Runtimes & Scripts"
        case .codeSnippets, .envProfiles, .ocrScreenGrabber, .logStream, .nlToCommand, .imageConverter, .appLanguageStripper:
            return "Code & Tooling"
            
        // System Configs
        case .appUninstaller, .orphanScanner, .brewGhost, .appLipo, .systemOptimizer:
            return "App Maintenance"
        case .serviceManager, .systemTweaks, .launchServices, .autoUpdateChecker, .logRotator:
            return "Services & Tweaks"
        case .permissionRepair, .extendedAttributes, .metadataEditor, .quarantineStripper, .dnsEditor:
            return "Permissions & Attributes"
            
        // Utilities & Desktop
        case .windowSnapping, .menuBarCustomizer, .desktopIcons, .hotCorners, .keyboardShortcuts, .displayProfiles, .nightShift, .keyboardBacklight, .trackpadGestures:
            return "Desktop & Window Controls"
        case .clipboardManager, .snippetExpander, .textCaseConverter, .characterCounter, .qrCode, .colorPicker, .screenRuler, .screenLoupe, .pdfToolbox, .markdownPreviewer:
            return "Tools & Converters"
        // Juicer Store
        case .creatorRepos:
            return "Creator Repositories & Ecosystem"
        default:
            return "General Helpers"
        }
    }
}
