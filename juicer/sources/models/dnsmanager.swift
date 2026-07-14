import Foundation

struct HostRecord: Identifiable, Hashable {
    let id: UUID = UUID()
    var ip: String
    var domain: String
    var isEnabled: Bool
    let isSystem: Bool
}

class DNSManager: ObservableObject {
    @Published var records: [HostRecord] = []
    @Published var isLoading = false
    @Published var isSaving = false
    
    private let hostsPath = "/etc/hosts"
    private let tempHostsPath = "/tmp/juicer_hosts"
    
    func loadHosts() {
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
                        // Check if the comment contains a commented out host record
                        isEnabled = false
                        trimmed = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    
                    let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    guard parts.count >= 2 else { continue }
                    
                    let ip = parts[0]
                    let domain = parts[1]
                    
                    // Simple check for valid IP (v4 contains dots, v6 contains colons)
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
                AppLogger.shared.log("Loaded \(self.records.count) host records.")
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
    }
    
    func saveHosts(completion: @escaping (Bool) -> Void) {
        self.isSaving = true
        AppLogger.shared.log("Requesting authorization to save host records...")
        
        Task.detached(priority: .userInitiated) {
            // Step 1: Construct the content string
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
            
            // Build non-system records
            var userRecords = ""
            let currentRecords = await MainActor.run { self.records }
            
            for record in currentRecords {
                // Skip system default entries in loops since they are in the header
                if record.isSystem { continue }
                
                let comment = record.isEnabled ? "" : "# "
                userRecords += "\(comment)\(record.ip)\t\(record.domain)\n"
            }
            
            let finalContent = header + userRecords
            
            // Step 2: Write to temporary file in user-space
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
            
            // Step 3: Run elevation using AppleScript
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
