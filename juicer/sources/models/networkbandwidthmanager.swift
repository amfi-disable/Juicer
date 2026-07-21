import Foundation
import Combine

struct ProcessNetworkStat: Identifiable, Hashable {
    var id: Int { pid }
    let pid: Int
    let processName: String
    let bytesIn: Int64
    let bytesOut: Int64
    var rateIn: Double = 0.0 // KB/s
    var rateOut: Double = 0.0 // KB/s
}

class NetworkBandwidthManager: ObservableObject {
    @Published var processStats: [ProcessNetworkStat] = []
    @Published var totalDownloadSpeed: Double = 0.0 // KB/s
    @Published var totalUploadSpeed: Double = 0.0 // KB/s
    @Published var isMonitoring = false
    
    private var timer: Timer?
    private var previousStats: [Int: (inBytes: Int64, outBytes: Int64)] = [:]
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        fetchNetworkStats()
        
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.fetchNetworkStats()
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
    }
    
    private func fetchNetworkStats() {
        Task.detached(priority: .userInitiated) {
            // Run nettop command in logging mode: nettop -P -L 1 -J bytes_in,bytes_out
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/nettop")
            process.arguments = ["-P", "-L", "1", "-J", "bytes_in,bytes_out"]
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe()
            
            try? process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            var currentStats: [ProcessNetworkStat] = []
            let lines = output.components(separatedBy: "\n")
            
            for line in lines {
                // Expected format: process_name.pid bytes_in bytes_out
                let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                guard parts.count >= 3 else { continue }
                
                let namePid = parts[0]
                guard let lastDot = namePid.lastIndex(of: "."),
                      let pid = Int(namePid[namePid.index(after: lastDot)...]) else { continue }
                let name = String(namePid[..<lastDot])
                
                guard let bIn = Int64(parts[1]), let bOut = Int64(parts[2]) else { continue }
                
                currentStats.append(ProcessNetworkStat(pid: pid, processName: name, bytesIn: bIn, bytesOut: bOut))
            }
            
            // Calculate delta rate (over 2 seconds interval)
            var newPreviousStats: [Int: (inBytes: Int64, outBytes: Int64)] = [:]
            var updatedList: [ProcessNetworkStat] = []
            var sumDown = 0.0
            var sumUp = 0.0
            
            for var item in currentStats {
                if let prev = self.previousStats[item.pid] {
                    let deltaIn = max(0, item.bytesIn - prev.inBytes)
                    let deltaOut = max(0, item.bytesOut - prev.outBytes)
                    item.rateIn = Double(deltaIn) / 1024.0 / 2.0 // KB/s
                    item.rateOut = Double(deltaOut) / 1024.0 / 2.0 // KB/s
                }
                newPreviousStats[item.pid] = (item.bytesIn, item.bytesOut)
                sumDown += item.rateIn
                sumUp += item.rateOut
                updatedList.append(item)
            }
            
            self.previousStats = newPreviousStats
            let sorted = updatedList.sorted(by: { ($0.rateIn + $0.rateOut) > ($1.rateIn + $1.rateOut) })
            
            await MainActor.run { [sumDown, sumUp, sorted] in
                self.processStats = sorted
                self.totalDownloadSpeed = sumDown
                self.totalUploadSpeed = sumUp
            }
        }
    }
}
