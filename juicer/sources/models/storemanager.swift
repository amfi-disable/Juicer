import Foundation
import AppKit
import Combine

// MARK: - Models

struct StoreApp: Identifiable, Codable, Hashable {
    let id: String           // Cask token or Formula name
    let name: String
    let desc: String
    let homepage: String
    let version: String
    let isCask: Bool
    let appNames: [String]   // Extracted from Cask artifacts (e.g. ["Visual Studio Code.app"])
    var pricing: PricingTag
    var status: InstallationStatus

    enum PricingTag: String, Codable, CaseIterable {
        case free = "Free"
        case freemium = "Freemium"
        case paid = "Paid"

        var colorName: String {
            switch self {
            case .free: return "green"
            case .freemium: return "orange"
            case .paid: return "blue"
            }
        }
    }

    enum InstallationStatus: String, Codable, CaseIterable {
        case notInstalled = "Not Installed"
        case installedViaHomebrew = "Installed via Homebrew"
        case installedExternally = "Installed Externally"
    }
}

// MARK: - Manager

class StoreManager: ObservableObject {
    @Published var apps: [StoreApp] = []
    @Published var outdatedApps: [StoreApp] = []
    @Published var isLoading: Bool = false
    @Published var isCheckingUpdates: Bool = false
    @Published var progressLog: String = ""
    @Published var isRunningAction: Bool = false
    @Published var errorMessage: String? = nil

    private let fm = FileManager.default
    private var actionProcess: Process?

    private var cacheDirectory: URL {
        let paths = fm.urls(for: .cachesDirectory, in: .userDomainMask)
        let root = paths.first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let dir = root.appendingPathComponent("com.even.juicer")
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: - Pre-categorizations for Casks (to ensure accurate tags)

    private static let paidCasks: Set<String> = [
        "1password", "dash", "sublime-text", "tower", "tableplus", "cleanmymac", "charles",
        "transmit", "nova", "sketch", "photoshop", "illustrator", "premiere", "microsoft-office",
        "microsoft-excel", "microsoft-word", "microsoft-powerpoint", "monosnap", "daisydisk",
        "path-finder", "omnigraffle", "omniplan", "omnioutliner", "omnifocus", "mmonit", "scapple",
        "scrivener", "balsamiq-wireframes", "beyond-compare", "araxis-merge", "kaleidoscope"
    ]

    private static let freemiumCasks: Set<String> = [
        "spotify", "slack", "zoom", "dropbox", "alfred", "figma", "postman", "docker", "notion",
        "todoist", "evernote", "trello", "skype", "warp", "gitkraken", "sourcetree", "lens",
        "teamviewer", "anydesk", "skitch", "canva", "lucidchart", "lark", "discord"
    ]

    // MARK: - Fetch & Parse (Async + Cache)

    func loadStore(forceRefresh: Bool = false) {
        isLoading = true
        errorMessage = nil

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            do {
                let casks = try await self.fetchCasks(forceRefresh: forceRefresh)
                let formulae = try await self.fetchFormulae(forceRefresh: forceRefresh)
                let combined = casks + formulae

                // Scan installation status of combined list
                let finalApps = self.scanStatuses(for: combined)

                await MainActor.run {
                    self.apps = finalApps
                    self.isLoading = false
                    self.checkForUpdates() // Trigger updates check automatically
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load Software Center: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    struct BrewOutdatedJSON: Codable {
        struct OutdatedItem: Codable {
            let name: String
            let current_version: String
        }
        let formulae: [OutdatedItem]
        let casks: [OutdatedItem]
    }

    func checkForUpdates() {
        guard !isCheckingUpdates else { return }
        isCheckingUpdates = true
        
        Task.detached(priority: .background) { [weak self] in
            guard let self else { return }
            
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/brew")
            proc.arguments = ["outdated", "--json"]
            
            let pipe = Pipe()
            proc.standardOutput = pipe
            proc.standardError = Pipe() // Ignore errors
            
            do {
                try proc.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                proc.waitUntilExit()
                
                if let decoded = try? JSONDecoder().decode(BrewOutdatedJSON.self, from: data) {
                    var outdatedList: [StoreApp] = []
                    
                    // Match casks
                    for cask in decoded.casks {
                        if let matched = self.apps.first(where: { $0.id == cask.name && $0.isCask }) {
                            var updated = matched
                            updated.status = .installedViaHomebrew // Flag as installed for updates view
                            outdatedList.append(updated)
                        } else {
                            // Dummy cask fallback
                            outdatedList.append(StoreApp(
                                id: cask.name, name: cask.name, desc: "Outdated graphical application.",
                                homepage: "", version: cask.current_version, isCask: true,
                                appNames: [], pricing: .free, status: .installedViaHomebrew
                            ))
                        }
                    }
                    
                    // Match formulae
                    for formula in decoded.formulae {
                        if let matched = self.apps.first(where: { $0.id == formula.name && !$0.isCask }) {
                            var updated = matched
                            updated.status = .installedViaHomebrew
                            outdatedList.append(updated)
                        } else {
                            // Dummy formula fallback
                            outdatedList.append(StoreApp(
                                id: formula.name, name: formula.name, desc: "Outdated command-line tool.",
                                homepage: "", version: formula.current_version, isCask: false,
                                appNames: [], pricing: .free, status: .installedViaHomebrew
                            ))
                        }
                    }
                    
                    await MainActor.run {
                        self.outdatedApps = outdatedList
                        self.isCheckingUpdates = false
                    }
                } else {
                    await MainActor.run { self.isCheckingUpdates = false }
                }
            } catch {
                await MainActor.run { self.isCheckingUpdates = false }
            }
        }
    }

    // MARK: - Fetch Casks

    private func fetchCasks(forceRefresh: Bool) async throws -> [StoreApp] {
        let cacheFile = cacheDirectory.appendingPathComponent("casks.json")

        // Load from cache if fresh
        if !forceRefresh, fm.fileExists(atPath: cacheFile.path) {
            if let attrs = try? fm.attributesOfItem(atPath: cacheFile.path),
               let modDate = attrs[.modificationDate] as? Date,
               Date().timeIntervalSince(modDate) < 86400 { // 24 hours cache
                if let data = try? Data(contentsOf: cacheFile),
                   let list = try? JSONDecoder().decode([StoreApp].self, from: data) {
                    return list
                }
            }
        }

        // Fetch from API
        guard let url = URL(string: "https://formulae.brew.sh/api/cask.json") else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)

        // Parse Homebrew schema
        guard let rawList = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw NSError(domain: "StoreManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid Cask JSON"])
        }

        var parsed: [StoreApp] = []
        for raw in rawList {
            guard let token = raw["token"] as? String,
                  let nameList = raw["name"] as? [String],
                  let name = nameList.first else { continue }

            let desc = raw["desc"] as? String ?? ""
            let homepage = raw["homepage"] as? String ?? ""
            let version = raw["version"] as? String ?? ""

            // Extract App names from artifacts
            var apps: [String] = []
            if let artifacts = raw["artifacts"] as? [[String: Any]] {
                for art in artifacts {
                    if let appList = art["app"] as? [String] {
                        apps.append(contentsOf: appList)
                    }
                }
            }

            let pricing = self.classifyPricing(token: token, desc: desc, homepage: homepage)

            parsed.append(StoreApp(
                id: token,
                name: name,
                desc: desc,
                homepage: homepage,
                version: version,
                isCask: true,
                appNames: apps,
                pricing: pricing,
                status: .notInstalled
            ))
        }

        // Save to cache
        if let encoded = try? JSONEncoder().encode(parsed) {
            try? encoded.write(to: cacheFile)
        }

        return parsed
    }

    // MARK: - Fetch Formulae

    private func fetchFormulae(forceRefresh: Bool) async throws -> [StoreApp] {
        let cacheFile = cacheDirectory.appendingPathComponent("formulae.json")

        // Load from cache if fresh
        if !forceRefresh, fm.fileExists(atPath: cacheFile.path) {
            if let attrs = try? fm.attributesOfItem(atPath: cacheFile.path),
               let modDate = attrs[.modificationDate] as? Date,
               Date().timeIntervalSince(modDate) < 86400 {
                if let data = try? Data(contentsOf: cacheFile),
                   let list = try? JSONDecoder().decode([StoreApp].self, from: data) {
                    return list
                }
            }
        }

        // Fetch from API
        guard let url = URL(string: "https://formulae.brew.sh/api/formula.json") else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)

        // Parse Homebrew schema
        guard let rawList = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw NSError(domain: "StoreManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid Formula JSON"])
        }

        var parsed: [StoreApp] = []
        for raw in rawList {
            guard let name = raw["name"] as? String,
                  let desc = raw["desc"] as? String else { continue }

            let homepage = raw["homepage"] as? String ?? ""
            let version = (raw["versions"] as? [String: Any])?["stable"] as? String ?? ""
            let license = raw["license"] as? String ?? ""

            // Categorize pricing based on license
            let pricing: StoreApp.PricingTag
            let licLower = license.lowercased()
            if licLower.contains("commercial") || licLower.contains("proprietary") {
                pricing = .paid
            } else if licLower.contains("shareware") || licLower.contains("trial") {
                pricing = .freemium
            } else {
                pricing = .free
            }

            parsed.append(StoreApp(
                id: name,
                name: name,
                desc: desc,
                homepage: homepage,
                version: version,
                isCask: false,
                appNames: [],
                pricing: pricing,
                status: .notInstalled
            ))
        }

        // Save to cache
        if let encoded = try? JSONEncoder().encode(parsed) {
            try? encoded.write(to: cacheFile)
        }

        return parsed
    }

    // MARK: - Classification Helper

    private func classifyPricing(token: String, desc: String, homepage: String) -> StoreApp.PricingTag {
        let lowerToken = token.lowercased()
        if StoreManager.paidCasks.contains(lowerToken) { return .paid }
        if StoreManager.freemiumCasks.contains(lowerToken) { return .freemium }

        let text = "\(desc) \(homepage)".lowercased()

        // Scan paid keywords
        let paidKeywords = ["commercial", "buy", "pricing", "trial version", "requires a license", "requires a paid", "subscription", "monthly fee", "yearly fee", "license key", "shareware"]
        for word in paidKeywords {
            if text.contains(word) { return .paid }
        }

        // Scan freemium keywords
        let freemiumKeywords = ["freemium", "free tier", "free basic", "free evaluation", "evaluation period", "in-app purchase", "partially free", "limited free"]
        for word in freemiumKeywords {
            if text.contains(word) { return .freemium }
        }

        return .free
    }

    // MARK: - Scan File System Installation Status

    private func scanStatuses(for list: [StoreApp]) -> [StoreApp] {
        var updated = list
        let homeDir = fm.homeDirectoryForCurrentUser.path

        // Query once: Applications folders contents
        let localAppsDir = "/Applications"
        let userAppsDir = "\(homeDir)/Applications"
        let installedApps: Set<String> = {
            var set = Set<String>()
            if let local = try? fm.contentsOfDirectory(atPath: localAppsDir) { set.formUnion(local) }
            if let user = try? fm.contentsOfDirectory(atPath: userAppsDir) { set.formUnion(user) }
            return set
        }()

        for i in updated.indices {
            let app = updated[i]

            if app.isCask {
                // Check Caskroom
                let caskroomPath = "/opt/homebrew/Caskroom/\(app.id)"
                if fm.fileExists(atPath: caskroomPath) {
                    updated[i].status = .installedViaHomebrew
                } else {
                    // Check if any of the app names are in /Applications
                    let existsInApps = app.appNames.contains { appName in
                        installedApps.contains(appName)
                    }
                    if existsInApps {
                        updated[i].status = .installedExternally
                    } else {
                        updated[i].status = .notInstalled
                    }
                }
            } else {
                // Check Cellar
                let cellarPath = "/opt/homebrew/Cellar/\(app.id)"
                if fm.fileExists(atPath: cellarPath) {
                    updated[i].status = .installedViaHomebrew
                } else {
                    // Check if on path but not in Homebrew
                    let pathBinary = "/opt/homebrew/bin/\(app.id)"
                    let usrLocalBinary = "/usr/local/bin/\(app.id)"
                    if (fm.fileExists(atPath: pathBinary) && !fm.fileExists(atPath: cellarPath)) || fm.fileExists(atPath: usrLocalBinary) {
                        updated[i].status = .installedExternally
                    } else {
                        updated[i].status = .notInstalled
                    }
                }
            }
        }

        return updated
    }

    // MARK: - Install / Uninstall Package (Background process runner)

    func runAction(action: String, app: StoreApp) {
        guard !isRunningAction else { return }

        isRunningAction = true
        progressLog = "⏳ Starting \(action) for \(app.name) (\(app.id)) via Homebrew...\n\n"

        let isCask = app.isCask
        let token = app.id

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/bin/sh")

            let args: [String]
            if isCask {
                args = ["-c", "/opt/homebrew/bin/brew \(action) --cask \(token) 2>&1"]
            } else {
                args = ["-c", "/opt/homebrew/bin/brew \(action) \(token) 2>&1"]
            }

            proc.arguments = args

            let pipe = Pipe()
            proc.standardOutput = pipe
            proc.standardError = pipe

            await MainActor.run {
                self.actionProcess = proc
            }

            let fileHandle = pipe.fileHandleForReading

            // Read output stream asynchronously
            fileHandle.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty else { return }
                if let str = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.progressLog += str
                    }
                }
            }

            do {
                try proc.run()
                proc.waitUntilExit()
                fileHandle.readabilityHandler = nil

                let status = proc.terminationStatus
                await MainActor.run {
                    self.isRunningAction = false
                    self.actionProcess = nil
                    if status == 0 {
                        self.progressLog += "\n✅ Success: \(action) completed successfully!\n"
                        // Refresh the UI status
                        self.loadStore()
                    } else {
                        self.progressLog += "\n❌ Error: process terminated with exit code \(status)\n"
                    }
                }
            } catch {
                fileHandle.readabilityHandler = nil
                await MainActor.run {
                    self.isRunningAction = false
                    self.actionProcess = nil
                    self.progressLog += "\n❌ Error: Failed to execute process: \(error.localizedDescription)\n"
                }
            }
        }
    }

    func cancelAction() {
        actionProcess?.terminate()
        actionProcess = nil
        isRunningAction = false
        progressLog += "\n🛑 Operation cancelled by user.\n"
    }
}
