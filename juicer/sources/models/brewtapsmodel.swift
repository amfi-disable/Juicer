import Foundation

struct BrewTap: Identifiable, Hashable, Codable {
    var id: String { name }
    let name: String
    let remote: String
    var healthStatus: TapHealthStatus?
}

struct TapHealthStatus: Codable, Hashable {
    enum Status: String, Codable {
        case active = "Active"
        case stale = "Stale"
        case archived = "Archived"
        case redirected = "Redirected"
        case missing = "Missing"
        case unknown = "Unknown"
    }
    
    var status: Status
    var movedTo: String?
    var lastChecked: Date
    
    var isStale: Bool {
        Date().timeIntervalSince(lastChecked) > 86400
    }
}

class BrewTapsManager: ObservableObject {
    static let shared = BrewTapsManager()
    
    @Published var taps: [BrewTap] = []
    @Published var isLoading = false
    @Published var isCheckingHealth = false
    
    private init() {
        loadCachedTaps()
    }
    
    private var cacheURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Juicer", isDirectory: true)
            .appendingPathComponent("taps_cache.json")
    }
    
    func loadCachedTaps() {
        guard let url = cacheURL, FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let cached = try JSONDecoder().decode([BrewTap].self, from: data)
            self.taps = cached
        } catch {
            AppLogger.shared.log("Failed to load cached taps: \(error.localizedDescription)")
        }
    }
    
    func saveCachedTaps() {
        guard let url = cacheURL else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        do {
            let data = try JSONEncoder().encode(taps)
            try data.write(to: url, options: .atomic)
        } catch {
            AppLogger.shared.log("Failed to save cached taps: \(error.localizedDescription)")
        }
    }
    
    func loadTaps() {
        guard let brew = BrewManager.brewPath else { return }
        self.isLoading = true
        
        Task.detached(priority: .userInitiated) {
            var loadedTaps: [BrewTap] = []
            
            // Query brew tap-info
            let process = Process()
            process.executableURL = URL(fileURLWithPath: brew)
            process.arguments = ["tap-info", "--json=v1", "--installed"]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe() // Silence errors
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    for item in json {
                        guard let name = item["name"] as? String else { continue }
                        let remote = (item["remote"] as? String) ?? ""
                        loadedTaps.append(BrewTap(name: name, remote: remote, healthStatus: nil))
                    }
                }
            } catch {
                AppLogger.shared.log("Failed to query tap-info: \(error.localizedDescription)")
            }
            
            // Fallback to simple listing if json failed or empty
            if loadedTaps.isEmpty {
                let process2 = Process()
                process2.executableURL = URL(fileURLWithPath: brew)
                process2.arguments = ["tap"]
                let pipe2 = Pipe()
                process2.standardOutput = pipe2
                if (try? process2.run()) != nil {
                    process2.waitUntilExit()
                    let data2 = pipe2.fileHandleForReading.readDataToEndOfFile()
                    if let raw = String(data: data2, encoding: .utf8) {
                        let lines = raw.components(separatedBy: "\n")
                        for line in lines {
                            let name = line.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !name.isEmpty {
                                loadedTaps.append(BrewTap(name: name, remote: "", healthStatus: nil))
                            }
                        }
                    }
                }
            }
            
            await MainActor.run {
                // Keep cached health statuses if matching
                for i in 0..<loadedTaps.count {
                    if let existing = self.taps.first(where: { $0.name == loadedTaps[i].name }) {
                        loadedTaps[i].healthStatus = existing.healthStatus
                    }
                }
                self.taps = loadedTaps.sorted(by: { $0.name < $1.name })
                self.isLoading = false
                self.saveCachedTaps()
            }
        }
    }
    
    func checkTapsHealth() {
        guard !taps.isEmpty else { return }
        self.isCheckingHealth = true
        
        Task.detached(priority: .background) {
            var updatedTaps = self.taps
            let session = URLSession(configuration: .ephemeral)
            
            for i in 0..<updatedTaps.count {
                let tap = updatedTaps[i]
                guard !tap.remote.isEmpty else { continue }
                
                // Convert git@github.com:User/Repo.git or https://github.com/User/Repo to API URL
                var targetURLString = tap.remote
                if targetURLString.hasPrefix("git@github.com:") {
                    targetURLString = targetURLString.replacingOccurrences(of: "git@github.com:", with: "https://github.com/")
                }
                if targetURLString.hasSuffix(".git") {
                    targetURLString = String(targetURLString.dropSuffix(".git"))
                }
                
                let apiPath = targetURLString.replacingOccurrences(of: "https://github.com/", with: "https://api.github.com/repos/")
                guard let apiURL = URL(string: apiPath) else { continue }
                
                var request = URLRequest(url: apiURL)
                request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
                request.setValue("JuicerApp", forHTTPHeaderField: "User-Agent")
                
                var status = TapHealthStatus.Status.unknown
                var movedTo: String? = nil
                
                do {
                    let (data, response) = try await session.data(for: request)
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode == 200 {
                            if let repoInfo = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let archived = repoInfo["archived"] as? Bool {
                                status = archived ? .archived : .active
                            } else {
                                status = .active
                            }
                        } else if httpResponse.statusCode == 301 || httpResponse.statusCode == 302 {
                            status = .redirected
                            if let location = httpResponse.allHeaderFields["Location"] as? String {
                                movedTo = location
                            }
                        } else if httpResponse.statusCode == 404 {
                            status = .missing
                        }
                    }
                } catch {
                    AppLogger.shared.log("Error checking tap health for \(tap.name): \(error.localizedDescription)")
                }
                
                updatedTaps[i].healthStatus = TapHealthStatus(status: status, movedTo: movedTo, lastChecked: Date())
            }
            
            await MainActor.run {
                self.taps = updatedTaps
                self.isCheckingHealth = false
                self.saveCachedTaps()
            }
        }
    }
    
    func addTap(name: String, completion: @escaping (Bool) -> Void) {
        guard let brew = BrewManager.brewPath else { return }
        
        AppLogger.shared.log("Tapping repository \(name)...")
        
        Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: brew)
            process.arguments = ["tap", name]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let exitStatus = process.terminationStatus
                await MainActor.run {
                    if exitStatus == 0 {
                        self.loadTaps()
                        completion(true)
                    } else {
                        let errData = pipe.fileHandleForReading.readDataToEndOfFile()
                        let errMsg = String(data: errData, encoding: .utf8) ?? ""
                        AppLogger.shared.log("Failed to tap \(name): \(errMsg)")
                        completion(false)
                    }
                }
            } catch {
                await MainActor.run {
                    completion(false)
                }
            }
        }
    }
    
    func removeTap(_ tap: BrewTap, completion: @escaping (Bool) -> Void) {
        guard let brew = BrewManager.brewPath else { return }
        
        AppLogger.shared.log("Untapping repository \(tap.name)...")
        
        Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: brew)
            process.arguments = ["untap", tap.name]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let exitStatus = process.terminationStatus
                await MainActor.run {
                    if exitStatus == 0 {
                        self.loadTaps()
                        completion(true)
                    } else {
                        let errData = pipe.fileHandleForReading.readDataToEndOfFile()
                        let errMsg = String(data: errData, encoding: .utf8) ?? ""
                        AppLogger.shared.log("Failed to untap \(tap.name): \(errMsg)")
                        completion(false)
                    }
                }
            } catch {
                await MainActor.run {
                    completion(false)
                }
            }
        }
    }
}

private extension String {
    func dropSuffix(_ suffix: String) -> String {
        if hasSuffix(suffix) {
            return String(dropLast(suffix.count))
        }
        return self
    }
}
