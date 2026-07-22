import Foundation

struct BrewGhostPackage: Identifiable, Codable, Hashable {
    var id: String { name }
    let name: String
    let daysIdle: Int
    let size: Int64
    let formattedSize: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case daysIdle = "days_idle"
        case size
        case formattedSize = "formatted_size"
    }
}

struct BrewGhostHistoryItem: Identifiable, Codable, Hashable {
    var id = UUID()
    let timestamp: Int64
    let package: String
    let size: Int64
    let daysIdle: Int
    
    enum CodingKeys: String, CodingKey {
        case timestamp
        case package
        case size
        case daysIdle = "days_idle"
    }
    
    var formattedDate: String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

class BrewGhostManager: ObservableObject {
    static let shared = BrewGhostManager()
    
    @Published var ghosts: [BrewGhostPackage] = []
    @Published var historyItems: [BrewGhostHistoryItem] = []
    @Published var isLoading = false
    @Published var statusMessage = ""
    @Published var daysThreshold: Int = 90
    
    private let fileManager = FileManager.default
    
    static var brewGhostPath: String? {
        let paths = [
            "/opt/homebrew/bin/brew-ghost",
            "/usr/local/bin/brew-ghost",
            "/usr/bin/brew-ghost"
        ]
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return nil
    }
    
    var configPath: String {
        NSString(string: "~/.config/brew-ghost/config.json").expandingTildeInPath
    }
    
    var historyPath: String {
        NSString(string: "~/.config/brew-ghost/history.json").expandingTildeInPath
    }
    
    init() {
        loadConfig()
    }
    
    func loadConfig() {
        if fileManager.fileExists(atPath: configPath),
           let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let threshold = json["days_threshold"] as? Int {
            self.daysThreshold = threshold
        }
    }
    
    func fetchGhosts() {
        guard let executable = Self.brewGhostPath else {
            self.statusMessage = "brew-ghost CLI utility not found in PATH."
            return
        }
        
        self.isLoading = true
        self.statusMessage = "Scanning Homebrew Cellar for idle ghosts..."
        
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            do {
                let output = try Self.runCommand(executable, arguments: ["--json"])
                if let data = output.data(using: .utf8),
                   let list = try? JSONDecoder().decode([BrewGhostPackage].self, from: data) {
                    await MainActor.run {
                        self.ghosts = list
                        self.isLoading = false
                        self.statusMessage = list.isEmpty ? "Cellar is clean! No ghost packages detected." : "Found \(list.count) idle ghost packages."
                    }
                } else {
                    await MainActor.run {
                        self.isLoading = false
                        self.statusMessage = "Failed to parse ghost scan output."
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.statusMessage = "Error running scan: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func fetchHistory() {
        guard fileManager.fileExists(atPath: historyPath),
              let data = try? Data(contentsOf: URL(fileURLWithPath: historyPath)),
              let items = try? JSONDecoder().decode([BrewGhostHistoryItem].self, from: data) else {
            self.historyItems = []
            return
        }
        self.historyItems = items.reversed()
    }
    
    func setDaysThreshold(_ days: Int) {
        guard let executable = Self.brewGhostPath else { return }
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            _ = try? Self.runCommand(executable, arguments: ["--days", "\(days)"])
            await MainActor.run {
                self.daysThreshold = days
                self.fetchGhosts()
            }
        }
    }
    
    func exorcise(package: String) {
        guard let brew = BrewManager.brewPath else { return }
        self.isLoading = true
        self.statusMessage = "Uninstalling \(package)..."
        
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            do {
                _ = try Self.runCommand(brew, arguments: ["uninstall", package])
                await MainActor.run {
                    self.fetchGhosts()
                    self.fetchHistory()
                    AppLogger.shared.log("Exorcised ghost package: \(package)")
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.statusMessage = "Failed to exorcise \(package): \(error.localizedDescription)"
                }
            }
        }
    }
    
    func clearHistory() {
        try? fileManager.removeItem(atPath: historyPath)
        self.historyItems = []
    }
    
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
