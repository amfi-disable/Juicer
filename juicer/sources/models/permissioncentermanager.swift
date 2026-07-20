import AppKit
import AVFoundation
import CoreLocation
import CoreGraphics
import ApplicationServices
import UserNotifications

enum juicerpermissionkind: String, CaseIterable, Identifiable {
    case fullDiskAccess
    case accessibility
    case screenRecording
    case inputMonitoring
    case automation
    case notifications
    case camera
    case microphone
    case location

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fullDiskAccess: return "Full Disk Access"
        case .accessibility: return "Accessibility"
        case .screenRecording: return "Screen Recording"
        case .inputMonitoring: return "Input Monitoring"
        case .automation: return "Automation"
        case .notifications: return "Notifications"
        case .camera: return "Camera"
        case .microphone: return "Microphone"
        case .location: return "Location Services"
        }
    }

    var detail: String {
        switch self {
        case .fullDiskAccess: return "Read protected Library and application data for cleanup and diagnostics."
        case .accessibility: return "Control and paste into other apps for Better Cmd-Tab, clipboard paste, and window tools."
        case .screenRecording: return "Capture window previews and screen pixels for Better Cmd-Tab, loupe, and annotation tools."
        case .inputMonitoring: return "Observe global keyboard shortcuts and input events while Juicer is in the background."
        case .automation: return "Allow approved Juicer actions to control Finder, System Events, or other automation targets."
        case .notifications: return "Show low-disk-space, update, and completion alerts."
        case .camera: return "Use camera-aware privacy indicators when that feature is enabled."
        case .microphone: return "Use microphone-aware privacy indicators when that feature is enabled."
        case .location: return "Read location status for network and location auditing features."
        }
    }

    var icon: String {
        switch self {
        case .fullDiskAccess: return "internaldrive.fill"
        case .accessibility: return "accessibility"
        case .screenRecording: return "record.circle"
        case .inputMonitoring: return "keyboard"
        case .automation: return "applescript"
        case .notifications: return "bell.badge"
        case .camera: return "camera.fill"
        case .microphone: return "mic.fill"
        case .location: return "location.fill"
        }
    }

    var settingsURL: URL? {
        if self == .notifications {
            return URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension")
        }

        let pane: String
        switch self {
        case .fullDiskAccess: pane = "Privacy_AllFiles"
        case .accessibility: pane = "Privacy_Accessibility"
        case .screenRecording: pane = "Privacy_ScreenCapture"
        case .inputMonitoring: pane = "Privacy_ListenEvent"
        case .automation: pane = "Privacy_Automation"
        case .notifications: pane = "Privacy"
        case .camera: pane = "Privacy_Camera"
        case .microphone: pane = "Privacy_Microphone"
        case .location: pane = "Privacy_LocationServices"
        }
        return URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)")
    }
}

final class permissioncentermanager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = permissioncentermanager()

    @Published private(set) var statuses: [juicerpermissionkind: String] = [:]
    private let locationManager = CLLocationManager()

    private override init() {
        super.init()
        locationManager.delegate = self
        refresh()
    }

    func refresh() {
        var next: [juicerpermissionkind: String] = [:]
        next[.fullDiskAccess] = onboardingview.checkFullDiskAccess() ? "allowed" : "needs approval"
        next[.accessibility] = AXIsProcessTrusted() ? "allowed" : "needs approval"
        next[.screenRecording] = CGPreflightScreenCaptureAccess() ? "allowed" : "needs approval"
        next[.inputMonitoring] = "settings required"
        next[.automation] = "settings required"
        next[.camera] = Self.avStatus(AVCaptureDevice.authorizationStatus(for: .video))
        next[.microphone] = Self.avStatus(AVCaptureDevice.authorizationStatus(for: .audio))
        next[.location] = Self.locationStatus(CLLocationManager.authorizationStatus())
        statuses = next

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.statuses[.notifications] = Self.notificationStatus(settings.authorizationStatus)
            }
        }
    }

    func request(_ permission: juicerpermissionkind) {
        switch permission {
        case .accessibility:
            _ = AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary)
        case .screenRecording:
            _ = CGRequestScreenCaptureAccess()
        case .notifications:
            NotificationManager.shared.requestAuthorization()
        case .camera:
            AVCaptureDevice.requestAccess(for: .video) { _ in self.refreshOnMain() }
        case .microphone:
            AVCaptureDevice.requestAccess(for: .audio) { _ in self.refreshOnMain() }
        case .location:
            locationManager.requestWhenInUseAuthorization()
        case .fullDiskAccess, .inputMonitoring, .automation:
            openSettings(for: permission)
        }
        refresh()
    }

    func requestAll() {
        [.accessibility, .screenRecording, .notifications, .camera, .microphone, .location].forEach(request)
        openPrivacySettings()
    }

    func openSettings(for permission: juicerpermissionkind) {
        guard let url = permission.settingsURL else { return }
        NSWorkspace.shared.open(url)
    }

    func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy") else { return }
        NSWorkspace.shared.open(url)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        refresh()
    }

    private func refreshOnMain() {
        DispatchQueue.main.async { self.refresh() }
    }

    private static func avStatus(_ status: AVAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "allowed"
        case .notDetermined: return "not requested"
        case .denied: return "denied"
        case .restricted: return "restricted"
        @unknown default: return "unknown"
        }
    }

    private static func locationStatus(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .authorized, .authorizedAlways, .authorizedWhenInUse: return "allowed"
        case .notDetermined: return "not requested"
        case .denied: return "denied"
        case .restricted: return "restricted"
        @unknown default: return "unknown"
        }
    }

    private static func notificationStatus(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized, .provisional, .ephemeral: return "allowed"
        case .notDetermined: return "not requested"
        case .denied: return "denied"
        @unknown default: return "unknown"
        }
    }
}
