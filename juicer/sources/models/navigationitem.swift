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
    case cpuMemoryMonitor, gpuMonitor, diskIOMonitor, networkTraffic, batteryHealth, startupItems, loginItemDelays, processKiller, systemLogs, kextManager, powerSchedule, thermalMonitor, fanController, memoryPurge, swapManager, vpnProfiles, networkLocations
    
    var id: NavigationItem { self }
    
    var workspace: JuicerWorkspace {
        switch self {
        case .appStore, .brewExplorer, .appUpdates:
            return .store
        case .dashboard, .statusMonitor, .portListener, .scriptConsole, .snapshots, .cpuMemoryMonitor, .gpuMonitor, .diskIOMonitor, .networkTraffic, .batteryHealth, .startupItems, .loginItemDelays, .processKiller, .systemLogs, .kextManager, .powerSchedule, .thermalMonitor, .fanController, .memoryPurge, .swapManager, .vpnProfiles, .networkLocations:
            return .system
        case .diskExplorer, .cacheCleaner, .devCaches, .largeFiles, .hiddenFiles, .diskVisualizer, .undoHistory:
            return .disk
        case .appUninstaller, .orphanScanner, .appLipo, .serviceManager, .systemTweaks, .quarantineStripper, .dnsEditor, .launchServices, .sdkSwitcher, .systemOptimizer, .tccViewer:
            return .configs
        case .utilitiesView:
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
        }
    }
}
