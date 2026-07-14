import Foundation

class BrewManager: ObservableObject {
    @Published var packages: [BrewPackage] = []
    @Published var isLoading = false
    @Published var doctorOutput = ""
    @Published var isRunningDoctor = false
    @Published var cleanupOutput = ""
    @Published var isRunningCleanup = false
    
    private let fileManager = FileManager.default
    
    // Find brew binary path
    static var brewPath: String? {
        let paths = [
            "/opt/homebrew/bin/brew",
            "/usr/local/bin/brew",
            "/usr/bin/brew",
            "/bin/brew"
        ]
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return nil
    }
    
    func loadPackages() {
        guard let brew = Self.brewPath else {
            AppLogger.shared.log("Homebrew not found on this system.")
            return
        }
        
        self.isLoading = true
        self.packages = []
        
        Task.detached(priority: .userInitiated) {
            var loadedPackages: [BrewPackage] = []
            
            // 1. Get Formulae list
            if let formulaOutput = try? Self.runCommand(brew, arguments: ["list", "--formula", "--versions"]) {
                let lines = formulaOutput.components(separatedBy: "\n")
                for line in lines {
                    let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    guard parts.count >= 2 else { continue }
                    let name = parts[0]
                    let version = parts[1]
                    loadedPackages.append(BrewPackage(name: name, version: version, type: .formula, isOutdated: false, latestVersion: nil))
                }
            }
            
            // 2. Get Casks list
            if let caskOutput = try? Self.runCommand(brew, arguments: ["list", "--cask", "--versions"]) {
                let lines = caskOutput.components(separatedBy: "\n")
                for line in lines {
                    let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    guard parts.count >= 2 else { continue }
                    let name = parts[0]
                    let version = parts[1]
                    loadedPackages.append(BrewPackage(name: name, version: version, type: .cask, isOutdated: false, latestVersion: nil))
                }
            }
            
            // 3. Mark outdated packages
            if let outdatedJSON = try? Self.runCommand(brew, arguments: ["outdated", "--json"]) {
                if let data = outdatedJSON.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    
                    // Parse formulae
                    if let formulaeList = json["formulae"] as? [[String: Any]] {
                        for item in formulaeList {
                            if let name = item["name"] as? String,
                               let latest = item["current_version"] as? String {
                                if let idx = loadedPackages.firstIndex(where: { $0.name == name && $0.type == .formula }) {
                                    loadedPackages[idx].isOutdated = true
                                    loadedPackages[idx].latestVersion = latest
                                }
                            }
                        }
                    }
                    
                    // Parse casks
                    if let casksList = json["casks"] as? [[String: Any]] {
                        for item in casksList {
                            if let name = item["name"] as? String,
                               let latest = item["current_version"] as? String {
                                if let idx = loadedPackages.firstIndex(where: { $0.name == name && $0.type == .cask }) {
                                    loadedPackages[idx].isOutdated = true
                                    loadedPackages[idx].latestVersion = latest
                                }
                            }
                        }
                    }
                }
            }
            
            let sorted = loadedPackages.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
            
            await MainActor.run {
                self.packages = sorted
                self.isLoading = false
                AppLogger.shared.log("Loaded \(self.packages.count) Homebrew packages.")
            }
        }
    }
    
    func upgradePackage(_ package: BrewPackage, completion: @escaping (Bool) -> Void) {
        guard let brew = Self.brewPath else { return }
        
        AppLogger.shared.log("Upgrading Homebrew package \(package.name)...")
        
        Task.detached(priority: .userInitiated) {
            do {
                _ = try Self.runCommand(brew, arguments: ["upgrade", package.name])
                await MainActor.run {
                    self.loadPackages()
                    completion(true)
                }
            } catch {
                AppLogger.shared.log("Failed to upgrade \(package.name): \(error.localizedDescription)")
                await MainActor.run {
                    completion(false)
                }
            }
        }
    }
    
    func uninstallPackage(_ package: BrewPackage, completion: @escaping (Bool) -> Void) {
        guard let brew = Self.brewPath else { return }
        
        AppLogger.shared.log("Uninstalling Homebrew package \(package.name)...")
        
        Task.detached(priority: .userInitiated) {
            do {
                _ = try Self.runCommand(brew, arguments: ["uninstall", package.name])
                await MainActor.run {
                    self.loadPackages()
                    completion(true)
                }
            } catch {
                AppLogger.shared.log("Failed to uninstall \(package.name): \(error.localizedDescription)")
                await MainActor.run {
                    completion(false)
                }
            }
        }
    }
    
    func runDoctor() {
        guard let brew = Self.brewPath else { return }
        
        self.isRunningDoctor = true
        self.doctorOutput = "Running brew doctor..."
        
        Task.detached(priority: .userInitiated) {
            do {
                let output = try Self.runCommand(brew, arguments: ["doctor"])
                await MainActor.run {
                    self.doctorOutput = output.isEmpty ? "Your system is ready to brew!" : output
                    self.isRunningDoctor = false
                }
            } catch {
                await MainActor.run {
                    self.doctorOutput = "Error running doctor: \(error.localizedDescription)"
                    self.isRunningDoctor = false
                }
            }
        }
    }
    
    func runCleanup() {
        guard let brew = Self.brewPath else { return }
        
        self.isRunningCleanup = true
        self.cleanupOutput = "Running brew cleanup..."
        
        Task.detached(priority: .userInitiated) {
            do {
                let output = try Self.runCommand(brew, arguments: ["cleanup"])
                await MainActor.run {
                    self.cleanupOutput = output.isEmpty ? "Cleanup completed successfully." : output
                    self.isRunningCleanup = false
                    AppLogger.shared.log("Reclaimed Homebrew cached space.")
                }
            } catch {
                await MainActor.run {
                    self.cleanupOutput = "Error running cleanup: \(error.localizedDescription)"
                    self.isRunningCleanup = false
                }
            }
        }
    }
    
    func fetchPackageInfo(name: String, completion: @escaping (String) -> Void) {
        guard let brew = Self.brewPath else {
            completion("Homebrew not found on this system.")
            return
        }
        
        Task.detached(priority: .userInitiated) {
            let output = (try? Self.runCommand(brew, arguments: ["info", name])) ?? "No information found."
            await MainActor.run {
                completion(output)
            }
        }
    }
    
    // Command runner helper
    private static func runCommand(_ executable: String, arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
