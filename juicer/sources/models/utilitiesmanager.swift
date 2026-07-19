import Cocoa
import SwiftUI
import Carbon

class UtilitiesManager: ObservableObject {
    static let shared = UtilitiesManager()
    
    // Utility Enable States
    @AppStorage("util.betterCmdTab") var betterCmdTabEnabled = false
    @AppStorage("util.clipboard") var clipboardEnabled = false
    @AppStorage("util.tiler") var tilerEnabled = false
    @AppStorage("util.scratchpad") var scratchpadEnabled = false
    @AppStorage("util.loupe") var loupeEnabled = false
    
    // Hotkey bindings (stored as keycodes)
    // 48 = Tab, 9 = V, 123 = Left, 124 = Right, 37 = L
    @AppStorage("hotkey.betterCmdTab") var betterCmdTabKey = 48
    @AppStorage("hotkey.clipboard") var clipboardKey = 9
    @AppStorage("hotkey.tilerLeft") var tilerLeftKey = 123
    @AppStorage("hotkey.tilerRight") var tilerRightKey = 124
    @AppStorage("hotkey.loupe") var loupeKey = 37
    
    // Clipboard history storage
    @Published var clipboardHistory: [String] = []
    
    private var lastChangeCount = 0
    private var clipboardTimer: Timer?
    private var globalMonitor: Any?
    private var betterCmdTabPanel: NSPanel?
    
    init() {
        setupClipboardTracker()
        setupGlobalHotkeyMonitor()
    }
    
    func setupClipboardTracker() {
        clipboardTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.clipboardEnabled else { return }
            let pb = NSPasteboard.general
            if pb.changeCount != self.lastChangeCount {
                self.lastChangeCount = pb.changeCount
                if let str = pb.string(forType: .string), !str.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    DispatchQueue.main.async {
                        if !self.clipboardHistory.contains(str) {
                            self.clipboardHistory.insert(str, at: 0)
                            if self.clipboardHistory.count > 50 {
                                self.clipboardHistory.removeLast()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func setupGlobalHotkeyMonitor() {
        // Global monitor for hotkey shortcuts
        globalMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            let flags = event.modifierFlags
            
            // Cmd + Option + V -> Trigger Clipboard overlay
            if self.clipboardEnabled && flags.contains([.command, .option]) && event.keyCode == self.clipboardKey {
                NotificationCenter.default.post(name: NSNotification.Name("juicer.util.triggerClipboard"), object: nil)
                return nil
            }
            
            // Option + Tab -> Trigger BetterCmdTab overlay
            if self.betterCmdTabEnabled && flags.contains([.option]) && event.keyCode == self.betterCmdTabKey {
                NotificationCenter.default.post(name: NSNotification.Name("juicer.util.triggerCmdTab"), object: nil)
                return nil
            }
            
            // Ctrl + Option + Left -> Snap Active Window Left
            if self.tilerEnabled && flags.contains([.control, .option]) && event.keyCode == self.tilerLeftKey {
                self.tileFrontmostWindow(direction: .left)
                return nil
            }
            
            // Ctrl + Option + Right -> Snap Active Window Right
            if self.tilerEnabled && flags.contains([.control, .option]) && event.keyCode == self.tilerRightKey {
                self.tileFrontmostWindow(direction: .right)
                return nil
            }
            
            // Cmd + Option + L -> Trigger Loupe Color Picker
            if self.loupeEnabled && flags.contains([.command, .option]) && event.keyCode == self.loupeKey {
                NotificationCenter.default.post(name: NSNotification.Name("juicer.util.triggerLoupe"), object: nil)
                return nil
            }
            
            return event
        }

        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.betterCmdTabEnabled else { return }
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags.contains(.option) && event.keyCode == self.betterCmdTabKey {
                self.showBetterCmdTabPanel()
            }
        }
    }

    func showBetterCmdTabPanel() {
        let windows = betterCmdTabWindows()
        if betterCmdTabPanel == nil {
            let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 620, height: 190), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            panel.isFloatingPanel = true
            panel.level = .statusBar
            panel.hidesOnDeactivate = false
            panel.hasShadow = true
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            betterCmdTabPanel = panel
        }
        let panel = betterCmdTabPanel!
        panel.contentView = NSHostingView(rootView: bettercmdtaboverlayview(windows: windows, select: { [weak self] app in
            app.activate(options: [.activateIgnoringOtherApps])
            self?.hideBetterCmdTabPanel()
        }, dismiss: { [weak self] in self?.hideBetterCmdTabPanel() }))
        if let screen = NSScreen.main ?? NSScreen.screens.first {
            let frame = panel.frame
            panel.setFrameOrigin(NSPoint(x: screen.visibleFrame.midX - frame.width / 2, y: screen.visibleFrame.midY - frame.height / 2))
        }
        panel.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    func hideBetterCmdTabPanel() {
        betterCmdTabPanel?.orderOut(nil)
    }

    private func betterCmdTabWindows() -> [bettercmdtabwindow] {
        guard let windowInfo = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else { return [] }
        let apps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
        return apps.compactMap { app in
            let matching = windowInfo.first { info in
                let owner = info[kCGWindowOwnerPID as String] as? Int32
                let layer = info[kCGWindowLayer as String] as? Int
                return owner == app.processIdentifier && layer == 0
            }
            guard let matching, let number = matching[kCGWindowNumber as String] as? CGWindowID else { return nil }
            let image = CGWindowListCreateImage(.null, .optionIncludingWindow, number, [.boundsIgnoreFraming, .bestResolution]).map { cgImage in
                NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            }
            return bettercmdtabwindow(id: number, app: app, image: image)
        }
    }
    
    enum TileDirection {
        case left, right
    }
    
    private func tileFrontmostWindow(direction: TileDirection) {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else { return }
        let appRef = AXUIElementCreateApplication(frontmostApp.processIdentifier)
        
        var temp: AnyObject?
        let err = AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &temp)
        guard err == .success, let windowRef = temp as! AXUIElement? else { return }
        
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.visibleFrame
        
        let targetWidth = screenRect.width / 2
        let targetHeight = screenRect.height
        let targetX = direction == .left ? screenRect.minX : screenRect.minX + targetWidth
        let targetY = screenRect.minY // Origin bottom-left in Cocoa
        
        // Convert Y coordinate: AX window coordinates have origin at top-left of primary display
        guard let primaryScreen = NSScreen.screens.first else { return }
        let primaryHeight = primaryScreen.frame.height
        let axY = primaryHeight - (targetY + targetHeight)
        
        var pos = CGPoint(x: targetX, y: axY)
        var size = CGSize(width: targetWidth, height: targetHeight)
        
        if let posValue = AXValueCreate(.cgPoint, &pos),
           let sizeValue = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(windowRef, kAXPositionAttribute as CFString, posValue)
            AXUIElementSetAttributeValue(windowRef, kAXSizeAttribute as CFString, sizeValue)
        }
    }
}
