import Foundation
import Combine

struct EnvVariable: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var key: String
    var value: String
    var isSecret: Bool
    
    init(key: String, value: String, isSecret: Bool? = nil) {
        self.key = key
        self.value = value
        if let isSecret = isSecret {
            self.isSecret = isSecret
        } else {
            // Auto-detect secret based on key name patterns
            let k = key.uppercased()
            self.isSecret = k.contains("SECRET") || k.contains("KEY") || k.contains("PASSWORD") ||
                            k.contains("TOKEN") || k.contains("AUTH") || k.contains("PRIVATE") ||
                            k.contains("CREDENTIAL") || k.contains("DATABASE_URL")
        }
    }
}

struct EnvProfile: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var projectPath: String
    var variables: [EnvVariable]
    var updatedAt: Date
}

class EnvProfileManager: ObservableObject {
    @Published var profiles: [EnvProfile] = []
    @Published var selectedProfileID: UUID? = nil
    
    private let storageKey = "juicer.envprofiles.data"
    
    init() {
        loadProfiles()
        if profiles.isEmpty {
            createSampleProfiles()
        }
    }
    
    func loadProfiles() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([EnvProfile].self, from: data) {
            self.profiles = decoded
        }
    }
    
    func saveProfiles() {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    func addProfile(name: String, projectPath: String = "", variables: [EnvVariable] = []) {
        let newProfile = EnvProfile(
            name: name,
            projectPath: projectPath,
            variables: variables,
            updatedAt: Date()
        )
        profiles.append(newProfile)
        selectedProfileID = newProfile.id
        saveProfiles()
    }
    
    func updateProfile(_ profile: EnvProfile) {
        if let idx = profiles.firstIndex(where: { $0.id == profile.id }) {
            var updated = profile
            updated.updatedAt = Date()
            profiles[idx] = updated
            saveProfiles()
        }
    }
    
    func deleteProfile(id: UUID) {
        profiles.removeAll { $0.id == id }
        if selectedProfileID == id {
            selectedProfileID = profiles.first?.id
        }
        saveProfiles()
    }
    
    func exportAsEnvString(profile: EnvProfile) -> String {
        profile.variables.map { "\($0.key)=\($0.value)" }.joined(separator: "\n")
    }
    
    func exportAsShellExport(profile: EnvProfile) -> String {
        profile.variables.map { "export \($0.key)=\"\($0.value)\"" }.joined(separator: "\n")
    }
    
    func parseEnvFile(content: String) -> [EnvVariable] {
        var result: [EnvVariable] = []
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            
            let parts = trimmed.components(separatedBy: "=")
            if parts.count >= 2 {
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let value = parts.dropFirst().joined(separator: "=").trimmingCharacters(in: CharacterSet(charactersIn: " \"'"))
                result.append(EnvVariable(key: key, value: value))
            }
        }
        return result
    }
    
    private func createSampleProfiles() {
        let devVars = [
            EnvVariable(key: "PORT", value: "3000"),
            EnvVariable(key: "NODE_ENV", value: "development"),
            EnvVariable(key: "DATABASE_URL", value: "postgres://localhost:5432/dev_db"),
            EnvVariable(key: "API_SECRET_KEY", value: "sk_dev_9876543210123456789"),
            EnvVariable(key: "JWT_SECRET", value: "super-secret-dev-jwt-token")
        ]
        
        let prodVars = [
            EnvVariable(key: "PORT", value: "8080"),
            EnvVariable(key: "NODE_ENV", value: "production"),
            EnvVariable(key: "DATABASE_URL", value: "postgres://prod-db.internal:5432/main"),
            EnvVariable(key: "AWS_ACCESS_KEY_ID", value: "AKIAIOSFODNN7EXAMPLE"),
            EnvVariable(key: "AWS_SECRET_ACCESS_KEY", value: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY")
        ]
        
        profiles = [
            EnvProfile(name: "Development Local", projectPath: "~/Projects/MyApp", variables: devVars, updatedAt: Date()),
            EnvProfile(name: "Production Staging", projectPath: "~/Projects/MyApp", variables: prodVars, updatedAt: Date())
        ]
        selectedProfileID = profiles.first?.id
        saveProfiles()
    }
}
