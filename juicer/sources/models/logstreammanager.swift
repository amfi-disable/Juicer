import Foundation
import Combine

struct LogEntry: Identifiable, Hashable {
    let id: UUID = UUID()
    let timestamp: String
    let process: String
    let subsystem: String
    let message: String
    let level: String
}

class LogStreamManager: ObservableObject {
    @Published var logEntries: [LogEntry] = []
    @Published var isStreaming: Bool = false
    @Published var filterSubsystem: String = ""
    @Published var filterProcess: String = ""
    @Published var filterLevel: String = "Default"
    
    private var process: Process?
    private var pipe: Pipe?
    
    func startStreaming() {
        guard !isStreaming else { return }
        isStreaming = true
        logEntries = []
        
        Task.detached(priority: .userInitiated) {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/log")
            
            var args = ["stream", "--style", "compact"]
            if !self.filterSubsystem.isEmpty {
                args.append(contentsOf: ["--predicate", "subsystem CONTAINS \"\(self.filterSubsystem)\""])
            } else if !self.filterProcess.isEmpty {
                args.append(contentsOf: ["--predicate", "process CONTAINS \"\(self.filterProcess)\""])
            }
            
            proc.arguments = args
            let p = Pipe()
            proc.standardOutput = p
            proc.standardError = Pipe()
            
            self.process = proc
            self.pipe = p
            
            do {
                try proc.run()
                let handle = p.fileHandleForReading
                
                handle.readabilityHandler = { [weak self] fileHandle in
                    let data = fileHandle.availableData
                    guard !data.isEmpty, let lineStr = String(data: data, encoding: .utf8) else { return }
                    
                    let lines = lineStr.components(separatedBy: .newlines)
                    var newEntries: [LogEntry] = []
                    
                    for line in lines where !line.trimmingCharacters(in: .whitespaces).isEmpty {
                        // Compact format: 2026-07-20 16:54:11.123456+0800 0x123 Default 0x0 100 0 processName: [subsystem] message
                        let entry = LogEntry(
                            timestamp: String(line.prefix(26)),
                            process: "macOS System",
                            subsystem: "system",
                            message: line,
                            level: line.contains("Error") ? "Error" : (line.contains("Fault") ? "Fault" : "Info")
                        )
                        newEntries.append(entry)
                    }
                    
                    DispatchQueue.main.async {
                        self?.logEntries.append(contentsOf: newEntries)
                        if (self?.logEntries.count ?? 0) > 1000 {
                            self?.logEntries.removeFirst(200)
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isStreaming = false
                }
            }
        }
    }
    
    func stopStreaming() {
        isStreaming = false
        pipe?.fileHandleForReading.readabilityHandler = nil
        process?.terminate()
        process = nil
        pipe = nil
    }
}
