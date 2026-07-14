import Foundation

struct QuarantineItem: Identifiable, Hashable {
    let id: UUID = UUID()
    let url: URL
    var name: String { url.lastPathComponent }
    var path: String { url.path }
    var status: String // "Stripped", "Failed", "Not Quarantined"
}

class QuarantineStripper: ObservableObject {
    @Published var processedItems: [QuarantineItem] = []
    @Published var isProcessing = false
    
    func stripQuarantine(for urls: [URL]) {
        self.isProcessing = true
        
        AppLogger.shared.log("Stripping quarantine attributes for \(urls.count) items...")
        
        Task.detached(priority: .userInitiated) {
            var results: [QuarantineItem] = []
            
            for url in urls {
                let path = url.path
                
                // First check if the com.apple.quarantine attribute exists
                let hasQuarantineAttr = self.checkQuarantineAttributeExists(at: path)
                
                if !hasQuarantineAttr {
                    AppLogger.shared.log("No Gatekeeper quarantine attribute found on: \(url.lastPathComponent)")
                    results.append(QuarantineItem(url: url, status: "Not Quarantined"))
                    continue
                }
                
                // Run recursive attribute delete
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
                // -r: recursive, -d: delete attribute
                process.arguments = ["-r", "-d", "com.apple.quarantine", path]
                
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe
                
                do {
                    try process.run()
                    process.waitUntilExit()
                    
                    let success = process.terminationStatus == 0
                    if success {
                        AppLogger.shared.log("Successfully stripped quarantine attribute from: \(url.lastPathComponent)")
                        results.append(QuarantineItem(url: url, status: "Stripped"))
                    } else {
                        let errData = pipe.fileHandleForReading.readDataToEndOfFile()
                        let errStr = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown xattr error"
                        AppLogger.shared.log("xattr failed for \(url.lastPathComponent): \(errStr)")
                        results.append(QuarantineItem(url: url, status: "Failed"))
                    }
                } catch {
                    AppLogger.shared.log("Failed to strip quarantine for \(url.lastPathComponent): \(error.localizedDescription)")
                    results.append(QuarantineItem(url: url, status: "Failed"))
                }
            }
            
            await MainActor.run {
                // Prepend new results
                self.processedItems.insert(contentsOf: results, at: 0)
                self.isProcessing = false
            }
        }
    }
    
    private func checkQuarantineAttributeExists(at path: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        process.arguments = [path]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            guard process.terminationStatus == 0 else { return false }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.contains("com.apple.quarantine")
            }
        } catch {
            return false
        }
        
        return false
    }
}
