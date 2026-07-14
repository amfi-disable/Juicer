import Foundation

class SystemTweaker: ObservableObject {
    @Published var keyRepeat = 2
    @Published var initialKeyRepeat = 15
    @Published var showHiddenFiles = false
    @Published var showPathBar = false
    @Published var disableFinderAnimations = false
    @Published var dockAutohideDelay: Double = 0.5
    @Published var dockAutohideTimeModifier: Double = 0.5
    @Published var screenshotLocation = "~/Desktop"
    @Published var screenshotDisableShadow = false
    @Published var screenshotFormat = "png"
    
    private let fileManager = FileManager.default
    
    func loadAllPreferences() {
        // Keyboard (Global Domain represented by -g or NSGlobalDomain)
        self.keyRepeat = readIntPreference(domain: "-g", key: "KeyRepeat") ?? 2
        self.initialKeyRepeat = readIntPreference(domain: "-g", key: "InitialKeyRepeat") ?? 15
        
        // Finder
        self.showHiddenFiles = readBoolPreference(domain: "com.apple.finder", key: "AppleShowAllFiles") ?? false
        self.showPathBar = readBoolPreference(domain: "com.apple.finder", key: "ShowPathbar") ?? false
        self.disableFinderAnimations = readBoolPreference(domain: "com.apple.finder", key: "DisableAllAnimations") ?? false
        
        // Dock
        self.dockAutohideDelay = readDoublePreference(domain: "com.apple.dock", key: "autohide-delay") ?? 0.5
        self.dockAutohideTimeModifier = readDoublePreference(domain: "com.apple.dock", key: "autohide-time-modifier") ?? 0.5
        
        // Screenshots
        self.screenshotLocation = readStringPreference(domain: "com.apple.screencapture", key: "location") ?? "~/Desktop"
        self.screenshotDisableShadow = readBoolPreference(domain: "com.apple.screencapture", key: "disable-shadow") ?? false
        self.screenshotFormat = readStringPreference(domain: "com.apple.screencapture", key: "type") ?? "png"
    }
    
    // MARK: - Save Handlers
    func saveKeyboardSettings() {
        writeIntPreference(domain: "-g", key: "KeyRepeat", value: keyRepeat)
        writeIntPreference(domain: "-g", key: "InitialKeyRepeat", value: initialKeyRepeat)
        AppLogger.shared.log("Keyboard repeat preferences updated. Please log out and log back in for changes to take effect globally.")
    }
    
    func saveFinderSettings() {
        writeBoolPreference(domain: "com.apple.finder", key: "AppleShowAllFiles", value: showHiddenFiles)
        writeBoolPreference(domain: "com.apple.finder", key: "ShowPathbar", value: showPathBar)
        writeBoolPreference(domain: "com.apple.finder", key: "DisableAllAnimations", value: disableFinderAnimations)
        restartProcess(named: "Finder")
    }
    
    func saveDockSettings() {
        writeDoublePreference(domain: "com.apple.dock", key: "autohide-delay", value: dockAutohideDelay)
        writeDoublePreference(domain: "com.apple.dock", key: "autohide-time-modifier", value: dockAutohideTimeModifier)
        restartProcess(named: "Dock")
    }
    
    func saveScreenshotSettings() {
        writeStringPreference(domain: "com.apple.screencapture", key: "location", value: screenshotLocation)
        writeBoolPreference(domain: "com.apple.screencapture", key: "disable-shadow", value: screenshotDisableShadow)
        writeStringPreference(domain: "com.apple.screencapture", key: "type", value: screenshotFormat)
        restartProcess(named: "SystemUIServer")
    }
    
    // MARK: - Defaults Read/Write Core
    private func readIntPreference(domain: String, key: String) -> Int? {
        let output = runDefaultsCommand(args: ["read", domain, key])
        return output.flatMap { Int($0) }
    }
    
    private func readBoolPreference(domain: String, key: String) -> Bool? {
        let output = runDefaultsCommand(args: ["read", domain, key])
        guard let output = output else { return nil }
        return output == "1" || output.lowercased() == "true" || output.lowercased() == "yes"
    }
    
    private func readDoublePreference(domain: String, key: String) -> Double? {
        let output = runDefaultsCommand(args: ["read", domain, key])
        return output.flatMap { Double($0) }
    }
    
    private func readStringPreference(domain: String, key: String) -> String? {
        return runDefaultsCommand(args: ["read", domain, key])
    }
    
    private func writeIntPreference(domain: String, key: String, value: Int) {
        _ = runDefaultsCommand(args: ["write", domain, key, "-int", String(value)])
    }
    
    private func writeBoolPreference(domain: String, key: String, value: Bool) {
        _ = runDefaultsCommand(args: ["write", domain, key, "-bool", value ? "true" : "false"])
    }
    
    private func writeDoublePreference(domain: String, key: String, value: Double) {
        _ = runDefaultsCommand(args: ["write", domain, key, "-float", String(value)])
    }
    
    private func writeStringPreference(domain: String, key: String, value: String) {
        _ = runDefaultsCommand(args: ["write", domain, key, value])
    }
    
    private func runDefaultsCommand(args: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = args
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            guard process.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return output?.isEmpty == false ? output : nil
        } catch {
            return nil
        }
    }
    
    private func restartProcess(named processName: String) {
        AppLogger.shared.log("Restarting \(processName) to apply tweaks...")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        process.arguments = [processName]
        
        do {
            try process.run()
            process.waitUntilExit()
            AppLogger.shared.log("\(processName) restarted successfully.")
        } catch {
            AppLogger.shared.log("Failed to restart \(processName): \(error.localizedDescription)")
        }
    }
}
