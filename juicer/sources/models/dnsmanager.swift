import Foundation
import AppKit

struct HostRecord: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var ip: String
    var domain: String
    var isEnabled: Bool
    let isSystem: Bool
}

struct DNSProfile: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var description: String
    var records: [HostRecord]
    var subscriptionURL: String?
}

class DNSManager: ObservableObject {
    @Published var records: [HostRecord] = []
    @Published var profiles: [DNSProfile] = []
    @Published var activeProfileId: UUID?
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var isDownloading = false
    
    private let hostsPath = "/etc/hosts"
    private let tempHostsPath = "/tmp/juicer_hosts"
    
    init() {
        loadProfiles()
        // If empty, seed default profiles
        if profiles.isEmpty {
            seedDefaultProfiles()
        }
        
        // Match active profile or default to System Default
        if activeProfileId == nil, let defaultProfile = profiles.first(where: { $0.name == "System Default" }) {
            activeProfileId = defaultProfile.id
            UserDefaults.standard.set(defaultProfile.id.uuidString, forKey: "juicer.dns.activeProfileId")
        }
        
        loadHosts()
    }
    
    func loadProfiles() {
        let key = "juicer.dns.profiles"
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([DNSProfile].self, from: data) {
            self.profiles = decoded
        }
        
        if let activeIdString = UserDefaults.standard.string(forKey: "juicer.dns.activeProfileId"),
           let uuid = UUID(uuidString: activeIdString) {
            self.activeProfileId = uuid
        }
    }
    
    func saveProfiles() {
        let key = "juicer.dns.profiles"
        if let encoded = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    private func seedDefaultProfiles() {
        let systemDefault = DNSProfile(
            name: "System Default",
            description: "Default macOS hosts configuration.",
            records: []
        )
        let adBlock = DNSProfile(
            name: "Ad Blocker (StevenBlack)",
            description: "Unified hosts ad-blocking and malware prevention filter.",
            records: [],
            subscriptionURL: "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
        )
        let devProfile = DNSProfile(
            name: "Developer Workspace",
            description: "Custom local mappings and development domains configuration.",
            records: []
        )
        
        self.profiles = [systemDefault, adBlock, devProfile]
        saveProfiles()
    }
    
    func selectProfile(profileId: UUID) {
        self.activeProfileId = profileId
        UserDefaults.standard.set(profileId.uuidString, forKey: "juicer.dns.activeProfileId")
        
        if let profile = profiles.first(where: { $0.id == profileId }) {
            if let subURL = profile.subscriptionURL, !subURL.isEmpty {
                downloadSubscription(profile: profile)
            } else {
                if profile.name == "System Default" {
                    loadHostsFromFile()
                } else {
                    self.records = profile.records
                }
            }
        }
    }
    
    func createProfile(name: String, description: String, subscriptionURL: String? = nil) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDesc = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }
        
        let newProfile = DNSProfile(
            name: cleanName,
            description: cleanDesc,
            records: [],
            subscriptionURL: subscriptionURL?.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        self.profiles.append(newProfile)
        saveProfiles()
    }
    
    func deleteProfile(profileId: UUID) {
        guard let profile = profiles.first(where: { $0.id == profileId }) else { return }
        // Prevent deleting system or default profiles
        guard profile.name != "System Default" && profile.name != "Ad Blocker (StevenBlack)" && profile.name != "Developer Workspace" else { return }
        
        if activeProfileId == profileId {
            if let system = profiles.first(where: { $0.name == "System Default" }) {
                selectProfile(profileId: system.id)
            }
        }
        
        self.profiles.removeAll { $0.id == profileId }
        saveProfiles()
    }
    
    func loadHosts() {
        guard let activeId = activeProfileId,
              let profile = profiles.first(where: { $0.id == activeId }) else {
            loadHostsFromFile()
            return
        }
        
        if profile.name == "System Default" {
            loadHostsFromFile()
        } else {
            self.records = profile.records
        }
    }
    
    private func loadHostsFromFile() {
        self.isLoading = true
        self.records = []
        AppLogger.shared.log("Reading /etc/hosts configuration...")
        
        Task.detached(priority: .userInitiated) {
            var parsed: [HostRecord] = []
            do {
                let content = try String(contentsOfFile: self.hostsPath, encoding: .utf8)
                let lines = content.components(separatedBy: "\n")
                for line in lines {
                    var trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { continue }
                    
                    var isEnabled = true
                    if trimmed.hasPrefix("#") {
                        isEnabled = false
                        trimmed = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    
                    let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    guard parts.count >= 2 else { continue }
                    
                    let ip = parts[0]
                    let domain = parts[1]
                    if ip.contains(".") || ip.contains(":") {
                        let isSystem = (domain == "localhost" || domain == "broadcasthost" || ip == "255.255.255.255" || ip == "::1" || domain.hasSuffix(".local"))
                        parsed.append(HostRecord(ip: ip, domain: domain, isEnabled: isEnabled, isSystem: isSystem))
                    }
                }
            } catch {
                AppLogger.shared.log("Failed to read /etc/hosts: \(error.localizedDescription)")
            }
            
            await MainActor.run {
                self.records = parsed
                self.isLoading = false
                AppLogger.shared.log("Loaded \(self.records.count) host records from file.")
            }
        }
    }
    
    func downloadSubscription(profile: DNSProfile) {
        guard let urlString = profile.subscriptionURL, let url = URL(string: urlString) else { return }
        self.isDownloading = true
        AppLogger.shared.log("Downloading hosts subscription from \(urlString)...")
        
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let content = String(data: data, encoding: .utf8) else {
                    throw NSError(domain: "DNSManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode subscription content as UTF-8"])
                }
                
                var parsed: [HostRecord] = []
                let lines = content.components(separatedBy: "\n")
                for line in lines {
                    var trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { continue }
                    if trimmed.hasPrefix("#") && !trimmed.contains(" ") { continue }
                    
                    var isEnabled = true
                    if trimmed.hasPrefix("#") {
                        isEnabled = false
                        trimmed = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    
                    let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    guard parts.count >= 2 else { continue }
                    
                    let ip = parts[0]
                    let domain = parts[1]
                    if (ip.contains(".") || ip.contains(":")) && !domain.hasPrefix("#") {
                        let isSystem = (domain == "localhost" || domain == "broadcasthost" || ip == "255.255.255.255" || ip == "::1" || domain.hasSuffix(".local"))
                        parsed.append(HostRecord(ip: ip, domain: domain, isEnabled: isEnabled, isSystem: isSystem))
                    }
                }
                
                await MainActor.run {
                    self.records = parsed
                    self.isDownloading = false
                    AppLogger.shared.log("Downloaded \(parsed.count) host records successfully.")
                    
                    // Save to profile
                    if let idx = self.profiles.firstIndex(where: { $0.id == profile.id }) {
                        self.profiles[idx].records = parsed
                        self.saveProfiles()
                    }
                }
            } catch {
                await MainActor.run {
                    self.isDownloading = false
                    AppLogger.shared.log("Failed to download hosts: \(error.localizedDescription)")
                    self.records = profile.records // fallback to previous records
                }
            }
        }
    }
    
    func addRecord(ip: String, domain: String) {
        let cleanIp = ip.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDomain = domain.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanIp.isEmpty, !cleanDomain.isEmpty else { return }
        
        let record = HostRecord(ip: cleanIp, domain: cleanDomain, isEnabled: true, isSystem: false)
        self.records.append(record)
        AppLogger.shared.log("Added mapping: \(cleanIp) -> \(cleanDomain) (unsaved)")
        
        // Update profile
        if let activeId = activeProfileId,
           let idx = profiles.firstIndex(where: { $0.id == activeId }) {
            profiles[idx].records = self.records
            saveProfiles()
        }
    }
    
    func saveHosts(completion: @escaping (Bool) -> Void) {
        self.isSaving = true
        AppLogger.shared.log("Requesting authorization to save host records...")
        
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            var header = """
            ##
            # Host Database
            #
            # localhost is used to configure the loopback interface
            # when the system is booting.  Do not change this entry.
            ##
            127.0.0.1\tlocalhost
            255.255.255.255\tbroadcasthost
            ::1\tlocalhost
            
            """
            
            var userRecords = ""
            let currentRecords = await MainActor.run { self.records }
            for record in currentRecords {
                if record.isSystem { continue }
                let comment = record.isEnabled ? "" : "# "
                userRecords += "\(comment)\(record.ip)\t\(record.domain)\n"
            }
            
            let finalContent = header + userRecords
            do {
                try finalContent.write(toFile: self.tempHostsPath, atomically: true, encoding: .utf8)
            } catch {
                AppLogger.shared.log("Failed to write temp hosts: \(error.localizedDescription)")
                await MainActor.run {
                    self.isSaving = false
                    completion(false)
                }
                return
            }
            
            let command = "mv \(self.tempHostsPath) \(self.hostsPath) && chmod 644 \(self.hostsPath) && killall -HUP mDNSResponder"
            let appleScriptSource = "do shell script \"\(command)\" with administrator privileges"
            
            let appleScript = NSAppleScript(source: appleScriptSource)
            var errorDict: NSDictionary?
            let resultDescriptor = appleScript?.executeAndReturnError(&errorDict)
            let success = resultDescriptor != nil
            
            await MainActor.run {
                self.isSaving = false
                if success {
                    AppLogger.shared.log("Successfully saved /etc/hosts and flushed DNS.")
                    if let activeId = self.activeProfileId,
                       let idx = self.profiles.firstIndex(where: { $0.id == activeId }) {
                        self.profiles[idx].records = self.records
                        self.saveProfiles()
                    }
                    self.loadHosts()
                } else {
                    let errMessage = errorDict?["NSAppleScriptErrorMessage"] as? String ?? "User cancelled or denied authentication."
                    AppLogger.shared.log("Failed to save: \(errMessage)")
                }
                completion(success)
            }
        }
    }
}
