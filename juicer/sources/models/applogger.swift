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
        let formattedMessage = "[\(timestamp)] \(message)"
        
        DispatchQueue.main.async {
            self.logs.append(formattedMessage)
            self.latestLog = message
            
            // Limit stored log size to prevent memory bloat
            if self.logs.count > 1000 {
                self.logs.removeFirst()
            }
        }
        print(formattedMessage)
    }
    
    func clear() {
        DispatchQueue.main.async {
            self.logs.removeAll()
            self.latestLog = "Logs cleared."
        }
    }
}
