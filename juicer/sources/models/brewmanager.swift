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
            
            // 1. Get Leaf packages from brew leaves
            var leafNames = Set<String>()
            if let leavesOutput = try? Self.runCommand(brew, arguments: ["leaves"]) {
                leafNames = Set(leavesOutput.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
            }
            
            // 2. Query detailed installed packages in JSON
            if let infoJSON = try? Self.runCommand(brew, arguments: ["info", "--json=v2", "--installed"]) {
                if let data = infoJSON.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    
                    // Parse Formulae
                    if let formulaeList = json["formulae"] as? [[String: Any]] {
                        for item in formulaeList {
                            let name = (item["name"] as? String) ?? ""
                            var version = "unknown"
                            if let installed = item["installed"] as? [[String: Any]],
                               let first = installed.first,
                               let ver = first["version"] as? String {
                                version = ver
                            }
                            let pinned = (item["pinned"] as? Bool) ?? false
                            let linked = (item["linked_keg"] != nil)
                            let isLeaf = leafNames.contains(name)
                            
                            var deps: [String] = []
                            if let buildDependencies = item["dependencies"] as? [String] {
                                deps = buildDependencies
                            }
                            
                            loadedPackages.append(BrewPackage(
                                name: name,
                                version: version,
                                type: .formula,
                                isOutdated: false,
                                latestVersion: nil,
                                isPinned: pinned,
                                isLinked: linked,
                                isLeaf: isLeaf,
                                dependencies: deps
                            ))
                        }
                    }
                    
                    // Parse Casks
                    if let casksList = json["casks"] as? [[String: Any]] {
                        for item in casksList {
                            let name = (item["token"] as? String) ?? ""
                            let version = (item["version"] as? String) ?? "unknown"
                            loadedPackages.append(BrewPackage(
                                name: name,
                                version: version,
                                type: .cask,
                                isOutdated: false,
                                latestVersion: nil,
                                isPinned: false,
                                isLinked: true,
                                isLeaf: true,
                                dependencies: []
                            ))
                        }
                    }
                }
            }
            
            // Fallback to simple listing if JSON parsed nothing
            if loadedPackages.isEmpty {
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
            }
            
            // 3. Mark outdated packages
            if let outdatedJSON = try? Self.runCommand(brew, arguments: ["outdated", "--json"]) {
                if let data = outdatedJSON.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    
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
    
    // MARK: - Advanced package actions
    
    func pinPackage(_ package: BrewPackage, completion: @escaping (Bool) -> Void) {
        guard let brew = Self.brewPath else { return }
        AppLogger.shared.log("Pinning Homebrew package \(package.name)...")
        Task.detached(priority: .userInitiated) {
            do {
                _ = try Self.runCommand(brew, arguments: ["pin", package.name])
                await MainActor.run {
                    self.loadPackages()
                    completion(true)
                }
            } catch {
                AppLogger.shared.log("Failed to pin \(package.name): \(error.localizedDescription)")
                await MainActor.run { completion(false) }
            }
        }
    }
    
    func unpinPackage(_ package: BrewPackage, completion: @escaping (Bool) -> Void) {
        guard let brew = Self.brewPath else { return }
        AppLogger.shared.log("Unpinning Homebrew package \(package.name)...")
        Task.detached(priority: .userInitiated) {
            do {
                _ = try Self.runCommand(brew, arguments: ["unpin", package.name])
                await MainActor.run {
                    self.loadPackages()
                    completion(true)
                }
            } catch {
                AppLogger.shared.log("Failed to unpin \(package.name): \(error.localizedDescription)")
                await MainActor.run { completion(false) }
            }
        }
    }
    
    func linkPackage(_ package: BrewPackage, completion: @escaping (Bool) -> Void) {
        guard let brew = Self.brewPath else { return }
        AppLogger.shared.log("Linking Homebrew package \(package.name)...")
        Task.detached(priority: .userInitiated) {
            do {
                _ = try Self.runCommand(brew, arguments: ["link", "--overwrite", package.name])
                await MainActor.run {
                    self.loadPackages()
                    completion(true)
                }
            } catch {
                AppLogger.shared.log("Failed to link \(package.name): \(error.localizedDescription)")
                await MainActor.run { completion(false) }
            }
        }
    }
    
    func unlinkPackage(_ package: BrewPackage, completion: @escaping (Bool) -> Void) {
        guard let brew = Self.brewPath else { return }
        AppLogger.shared.log("Unlinking Homebrew package \(package.name)...")
        Task.detached(priority: .userInitiated) {
            do {
                _ = try Self.runCommand(brew, arguments: ["unlink", package.name])
                await MainActor.run {
                    self.loadPackages()
                    completion(true)
                }
            } catch {
                AppLogger.shared.log("Failed to unlink \(package.name): \(error.localizedDescription)")
                await MainActor.run { completion(false) }
            }
        }
    }
    
    // MARK: - Autoremove and Brewfile backup operations
    
    func runAutoremove(completion: @escaping (Bool, String) -> Void) {
        guard let brew = Self.brewPath else { return }
        AppLogger.shared.log("Running brew autoremove...")
        Task.detached(priority: .userInitiated) {
            do {
                let log = try Self.runCommand(brew, arguments: ["autoremove"])
                await MainActor.run {
                    self.loadPackages()
                    completion(true, log.isEmpty ? "No orphaned packages found to remove." : log)
                }
            } catch {
                await MainActor.run {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
    
    func exportBrewfile(to url: URL, completion: @escaping (Bool) -> Void) {
        guard let brew = Self.brewPath else { return }
        AppLogger.shared.log("Exporting Brewfile to \(url.path)...")
        Task.detached(priority: .userInitiated) {
            do {
                _ = try Self.runCommand(brew, arguments: ["bundle", "dump", "--force", "--file=\(url.path)"])
                await MainActor.run {
                    completion(true)
                }
            } catch {
                AppLogger.shared.log("Failed to export Brewfile: \(error.localizedDescription)")
                await MainActor.run { completion(false) }
            }
        }
    }
    
    func importBrewfile(from url: URL, completion: @escaping (Bool, String) -> Void) {
        guard let brew = Self.brewPath else { return }
        AppLogger.shared.log("Importing Brewfile from \(url.path)...")
        Task.detached(priority: .userInitiated) {
            do {
                let log = try Self.runCommand(brew, arguments: ["bundle", "--file=\(url.path)"])
                await MainActor.run {
                    self.loadPackages()
                    completion(true, log.isEmpty ? "All packages from Brewfile installed." : log)
                }
            } catch {
                await MainActor.run {
                    completion(false, error.localizedDescription)
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
