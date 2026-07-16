import Foundation

struct BrewService: Identifiable, Hashable, Codable {
    var id: String { name }
    let name: String
    var status: ServiceStatus
    let user: String?
    let plistPath: String?
    var ports: [Int] = []
    var customLinks: [ServiceLink] = []
    
    enum ServiceStatus: String, Codable {
        case started = "started"
        case stopped = "stopped"
        case error = "error"
        case unknown = "unknown"
    }
}

struct ServiceLink: Identifiable, Hashable, Codable {
    var id = UUID()
    let label: String
    let urlString: String
}

class BrewServicesManager: ObservableObject {
    static let shared = BrewServicesManager()
    
    @Published var services: [BrewService] = []
    @Published var isLoading = false
    @Published var isSystemDomain = false // true = root/sudo, false = user
    
    private init() {
        loadCustomLinks()
    }
    
    func loadServices() {
        guard let brew = BrewManager.brewPath else { return }
        self.isLoading = true
        
        Task.detached(priority: .userInitiated) {
            var loadedServices: [BrewService] = []
            
            // 1. Query brew services list
            let process = Process()
            process.executableURL = URL(fileURLWithPath: brew)
            var args = ["services", "list"]
            if self.isSystemDomain {
                // To list system services, we could run sudo, but standard list shows both with status.
                // We'll parse standard list output.
            }
            process.arguments = args
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe()
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let raw = String(data: data, encoding: .utf8) {
                    let lines = raw.components(separatedBy: "\n")
                    // Skip header line: Name Status User File
                    for line in lines.dropFirst() {
                        let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                        guard parts.count >= 2 else { continue }
                        let name = parts[0]
                        let statusRaw = parts[1]
                        
                        var status = BrewService.ServiceStatus.unknown
                        if statusRaw.contains("started") {
                            status = .started
                        } else if statusRaw.contains("stopped") {
                            status = .stopped
                        } else if statusRaw.contains("error") {
                            status = .error
                        }
                        
                        let user = parts.count >= 3 ? parts[2] : nil
                        let file = parts.count >= 4 ? parts[3] : nil
                        
                        loadedServices.append(BrewService(name: name, status: status, user: user, plistPath: file))
                    }
                }
            } catch {
                AppLogger.shared.log("Failed to list brew services: \(error.localizedDescription)")
            }
            
            // 2. Scan ports for started services
            let listeningPorts = self.scanListeningPorts()
            for i in 0..<loadedServices.count {
                if loadedServices[i].status == .started {
                    // Try to match process ports by service name
                    let serviceName = loadedServices[i].name
                    if let matchedPorts = listeningPorts[serviceName] {
                        loadedServices[i].ports = Array(matchedPorts).sorted()
                    }
                }
            }
            
            // 3. Load custom links from UserDefaults
            let customLinksMap = self.loadCustomLinksMap()
            for i in 0..<loadedServices.count {
                let name = loadedServices[i].name
                if let links = customLinksMap[name] {
                    loadedServices[i].customLinks = links
                }
            }
            
            await MainActor.run {
                self.services = loadedServices.sorted(by: { $0.name < $1.name })
                self.isLoading = false
            }
        }
    }
    
    func startService(_ service: BrewService, completion: @escaping (Bool) -> Void) {
        runServiceCommand("start", name: service.name, completion: completion)
    }
    
    func stopService(_ service: BrewService, completion: @escaping (Bool) -> Void) {
        runServiceCommand("stop", name: service.name, completion: completion)
    }
    
    func restartService(_ service: BrewService, completion: @escaping (Bool) -> Void) {
        runServiceCommand("restart", name: service.name, completion: completion)
    }
    
    private func runServiceCommand(_ command: String, name: String, completion: @escaping (Bool) -> Void) {
        guard let brew = BrewManager.brewPath else { return }
        
        AppLogger.shared.log("Running brew services \(command) for \(name)...")
        
        Task.detached(priority: .userInitiated) {
            let process = Process()
            
            if self.isSystemDomain {
                // Run using sudo with privileges escalation
                process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
                process.arguments = [brew, "services", command, name]
            } else {
                process.executableURL = URL(fileURLWithPath: brew)
                process.arguments = ["services", command, name]
            }
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let exitCode = process.terminationStatus
                await MainActor.run {
                    if exitCode == 0 {
                        self.loadServices()
                        completion(true)
                    } else {
                        let errData = pipe.fileHandleForReading.readDataToEndOfFile()
                        let errMsg = String(data: errData, encoding: .utf8) ?? ""
                        AppLogger.shared.log("Failed to run services \(command) for \(name): \(errMsg)")
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
    
    // Scan listening processes via lsof
    private func scanListeningPorts() -> [String: Set<Int>] {
        var results: [String: Set<Int>] = [:]
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        process.arguments = ["-nP", "-iTCP", "-sTCP:LISTEN"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let raw = String(data: data, encoding: .utf8) {
                let lines = raw.components(separatedBy: "\n")
                for line in lines.dropFirst() {
                    let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    guard parts.count >= 9 else { continue }
                    
                    let commandName = parts[0].lowercased()
                    let nameField = parts[8] // e.g. "127.0.0.1:5432" or "*:80"
                    
                    // Extract port
                    let hostParts = nameField.components(separatedBy: ":")
                    guard let portString = hostParts.last, let port = Int(portString) else { continue }
                    
                    // Clean up command name to match homebrew services
                    // E.g. "postgres" -> "postgresql", "redis-serv" -> "redis"
                    var matchedService = commandName
                    if commandName.contains("postgres") { matchedService = "postgresql" }
                    else if commandName.contains("redis") { matchedService = "redis" }
                    else if commandName.contains("nginx") { matchedService = "nginx" }
                    else if commandName.contains("mysql") { matchedService = "mysql" }
                    else if commandName.contains("mongod") { matchedService = "mongodb" }
                    else if commandName.contains("sync") { matchedService = "syncthing" }
                    else if commandName.contains("dnsmasq") { matchedService = "dnsmasq" }
                    
                    if results[matchedService] == nil {
                        results[matchedService] = []
                    }
                    results[matchedService]?.insert(port)
                }
            }
        } catch {
            AppLogger.shared.log("Failed to run lsof for services port scan: \(error.localizedDescription)")
        }
        
        return results
    }
    
    // MARK: - Custom Links persistence
    
    private func loadCustomLinksMap() -> [String: [ServiceLink]] {
        guard let data = UserDefaults.standard.data(forKey: "juicer.brew.services.customlinks") else { return [:] }
        return (try? JSONDecoder().decode([String: [ServiceLink]].self, from: data)) ?? [:]
    }
    
    private func loadCustomLinks() {
        // Triggers initial load if needed
    }
    
    func saveCustomLinks(for serviceName: String, links: [ServiceLink]) {
        var map = loadCustomLinksMap()
        map[serviceName] = links
        
        if let data = try? JSONEncoder().encode(map) {
            UserDefaults.standard.set(data, forKey: "juicer.brew.services.customlinks")
            // Reload services to refresh model state
            loadServices()
        }
    }
}
