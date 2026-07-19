import Foundation
import Combine

class AppLogger: ObservableObject {
    static let shared = AppLogger()
    
    @Published var logs: [String] = []
    @Published var latestLog: String = "Application initialized."
    
    private init() {}
    
    func log(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        let value = UserDefaults.standard.object(forKey: "juicer.settings.maskSensitiveLogs") as? Bool ?? true
            ? maskSensitiveValues(message)
            : message
        let formattedMessage = "[\(timestamp)] \(value)"
        
        DispatchQueue.main.async {
            self.logs.append(formattedMessage)
            self.latestLog = value
            
            // Limit stored log size to prevent memory bloat
            if self.logs.count > 1000 {
                self.logs.removeFirst()
            }
        }
        print(formattedMessage)
    }

    private func maskSensitiveValues(_ message: String) -> String {
        let patterns = ["token", "password", "secret", "api_key", "apikey", "private_key"]
        var result = message
        for pattern in patterns {
            result = result.replacingOccurrences(of: "(?i)(\(pattern)\\s*[:=]\\s*)[^\\s,;]+", with: "$1••••", options: .regularExpression)
        }
        return result
    }
    
    func clear() {
        DispatchQueue.main.async {
            self.logs.removeAll()
            self.latestLog = "Logs cleared."
        }
    }
}
