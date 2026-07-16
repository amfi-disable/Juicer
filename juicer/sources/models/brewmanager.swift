import Foundation

class BrewManager: ObservableObject {
    static let shared = BrewManager()

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
        
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            var loadedPackages: [BrewPackage] = []
            
            // 1. Run lightweight list --versions for fast initial rendering (takes ~0.2s)
            var formulaVersions: [String: String] = [:]
            if let formulaOutput = try? Self.runCommand(brew, arguments: ["list", "--formula", "--versions"]) {
                let lines = formulaOutput.components(separatedBy: "\n")
                for line in lines {
                    let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    guard parts.count >= 2 else { continue }
                    formulaVersions[parts[0]] = parts[1]
                    loadedPackages.append(BrewPackage(name: parts[0], version: parts[1], type: .formula, isOutdated: false, latestVersion: nil))
                }
            }
            
            var caskVersions: [String: String] = [:]
            if let caskOutput = try? Self.runCommand(brew, arguments: ["list", "--cask", "--versions"]) {
                let lines = caskOutput.components(separatedBy: "\n")
                for line in lines {
                    let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    guard parts.count >= 2 else { continue }
                    caskVersions[parts[0]] = parts[1]
                    loadedPackages.append(BrewPackage(name: parts[0], version: parts[1], type: .cask, isOutdated: false, latestVersion: nil))
                }
            }
            
            let initialSorted = loadedPackages.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
            
            // Update UI instantly with fast list!
            await MainActor.run {
                self.packages = initialSorted
                self.isLoading = false
                AppLogger.shared.log("Fast loaded \(self.packages.count) Homebrew packages. Fetching metadata in the background...")
            }
            
            // 2. Asynchronously enrich leaf/outdated status in background (does not block UI loading)
            var leafNames = Set<String>()
            if let leavesOutput = try? Self.runCommand(brew, arguments: ["leaves"]) {
                leafNames = Set(leavesOutput.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
            }
            
            // Query detailed info and outdated status
            if let infoJSON = try? Self.runCommand(brew, arguments: ["info", "--json=v2", "--installed"]) {
                if let data = infoJSON.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    
                    var enrichedMap: [String: BrewPackage] = [:]
                    for pkg in loadedPackages {
                        enrichedMap[pkg.name + "_" + pkg.type.rawValue] = pkg
                    }
                    
                    if let formulaeList = json["formulae"] as? [[String: Any]] {
                        for item in formulaeList {
                            let name = (item["name"] as? String) ?? ""
                            let key = name + "_formula"
                            if var pkg = enrichedMap[key] {
                                pkg.isPinned = (item["pinned"] as? Bool) ?? false
                                pkg.isLinked = (item["linked_keg"] != nil)
                                pkg.isLeaf = leafNames.contains(name)
                                if let buildDependencies = item["dependencies"] as? [String] {
                                    pkg.dependencies = buildDependencies
                                }
                                enrichedMap[key] = pkg
                            }
                        }
                    }
                    
                    if let casksList = json["casks"] as? [[String: Any]] {
                        for item in casksList {
                            let name = (item["token"] as? String) ?? ""
                            let key = name + "_cask"
                            if var pkg = enrichedMap[key] {
                                pkg.isLeaf = true
                                enrichedMap[key] = pkg
                            }
                        }
                    }
                    
                    // Mark outdated in background
                    if let outdatedJSON = try? Self.runCommand(brew, arguments: ["outdated", "--json"]) {
                        if let oData = outdatedJSON.data(using: .utf8),
                           let oJson = try? JSONSerialization.jsonObject(with: oData) as? [String: Any] {
                            
                            if let formulaeList = oJson["formulae"] as? [[String: Any]] {
                                for item in formulaeList {
                                    if let name = item["name"] as? String,
                                       let latest = item["current_version"] as? String {
                                        let key = name + "_formula"
                                        if var pkg = enrichedMap[key] {
                                            pkg.isOutdated = true
                                            pkg.latestVersion = latest
                                            enrichedMap[key] = pkg
                                        }
                                    }
                                }
                            }
                            
                            if let casksList = oJson["casks"] as? [[String: Any]] {
                                for item in casksList {
                                    if let name = item["name"] as? String,
                                       let latest = item["current_version"] as? String {
                                        let key = name + "_cask"
                                        if var pkg = enrichedMap[key] {
                                            pkg.isOutdated = true
                                            pkg.latestVersion = latest
                                            enrichedMap[key] = pkg
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    let finalSorted = Array(enrichedMap.values).sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
                    await MainActor.run {
                        self.packages = finalSorted
                        AppLogger.shared.log("Enriched background metadata for \(self.packages.count) Homebrew packages.")
                    }
                }
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
