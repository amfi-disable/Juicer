import Foundation

struct LaunchdService: Identifiable, Hashable {
    let id: UUID = UUID()
    let label: String
    let programArguments: [String]
    let runAtLoad: Bool
    let keepAlive: Bool
    let plistURL: URL
    let type: String // "User Agent", "Global Agent", "Global Daemon"
    var pid: Int? // If running
    var lastExitStatus: Int? // If stopped with status
    var isEnabled: Bool = true
    
    var filename: String { plistURL.lastPathComponent }
    var filepath: String { plistURL.path }
    
    var commandLine: String {
        programArguments.joined(separator: " ")
    }
    
    var statusDescription: String {
        if let pid = pid {
            return "Running (PID: \(pid))"
        } else if let exitStatus = lastExitStatus {
            return "Stopped (Exit Code: \(exitStatus))"
        } else {
            return "Stopped"
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(label)
        hasher.combine(plistURL)
    }
    
    static func == (lhs: LaunchdService, rhs: LaunchdService) -> Bool {
        return lhs.label == rhs.label && lhs.plistURL == rhs.plistURL
    }
    
    init?(plistURL: URL, type: String) {
        self.plistURL = plistURL
        self.type = type
        
        guard let plistData = try? Data(contentsOf: plistURL),
              let plistDict = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
            return nil
        }
        
        self.label = plistDict["Label"] as? String ?? plistURL.deletingPathExtension().lastPathComponent
        
        if let args = plistDict["ProgramArguments"] as? [String] {
            self.programArguments = args
        } else if let prog = plistDict["Program"] as? String {
            self.programArguments = [prog]
        } else {
            self.programArguments = []
        }
        
        self.runAtLoad = plistDict["RunAtLoad"] as? Bool ?? false
        
        if let keep = plistDict["KeepAlive"] as? Bool {
            self.keepAlive = keep
        } else if plistDict["KeepAlive"] != nil {
            // KeepAlive can be a dictionary of conditions (e.g. SuccessfulExit)
            self.keepAlive = true
        } else {
            self.keepAlive = false
        }
    }
    
    // Initializer to create a service from raw fields (for the form editor)
    init(label: String, programArguments: [String], runAtLoad: Bool, keepAlive: Bool, plistURL: URL, type: String) {
        self.label = label
        self.programArguments = programArguments
        self.runAtLoad = runAtLoad
        self.keepAlive = keepAlive
        self.plistURL = plistURL
        self.type = type
    }
    
    // Convert current configuration to a Property List dictionary
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "Label": label,
            "RunAtLoad": runAtLoad,
            "KeepAlive": keepAlive
        ]
        
        if !programArguments.isEmpty {
            dict["ProgramArguments"] = programArguments
        }
        
        return dict
    }
}
