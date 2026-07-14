import Foundation

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
    
    var id: NavigationItem { self }
    
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
        }
    }
}
