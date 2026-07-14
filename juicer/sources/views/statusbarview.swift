import SwiftUI

struct statusbarview: View {
    @ObservedObject var logger = AppLogger.shared
    
    @State private var diskUsageString: String = ""
    @State private var memoryUsageString: String = ""
    @State private var timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 20) {
            // Logs display
            HStack(spacing: 8) {
                Image(systemName: "terminal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(logger.latestLog)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
                .frame(height: 16)
            
            // Disk usage display
            HStack(spacing: 6) {
                Image(systemName: "square.grid.3x1.below.line.grid.1x2")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Disk: \(diskUsageString)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
                .frame(height: 16)
            
            // Memory display
            HStack(spacing: 6) {
                Image(systemName: "memorychip")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("RAM: \(memoryUsageString)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
        .border(Color.secondary.opacity(0.15), width: 1)
        .onAppear {
            updateMetrics()
        }
        .onReceive(timer) { _ in
            updateMetrics()
        }
    }
    
    private func updateMetrics() {
        // Update Disk Metrics
        let fileManager = FileManager.default
        if let values = try? fileManager.attributesOfFileSystem(forPath: "/"),
           let totalBytes = values[.systemSize] as? Int64,
           let freeBytes = values[.systemFreeSize] as? Int64 {
            let usedBytes = totalBytes - freeBytes
            let byteFormatter = ByteCountFormatter()
            byteFormatter.countStyle = .file
            byteFormatter.allowedUnits = [.useGB]
            let usedString = byteFormatter.string(fromByteCount: usedBytes)
            let totalString = byteFormatter.string(fromByteCount: totalBytes)
            diskUsageString = "\(usedString) / \(totalString)"
        }
        
        // Update Memory Metrics using mach host call
        let mem = getMemoryUsage()
        let byteFormatter = ByteCountFormatter()
        byteFormatter.countStyle = .memory
        byteFormatter.allowedUnits = [.useGB]
        let usedMemString = byteFormatter.string(fromByteCount: Int64(mem.used))
        let totalMemString = byteFormatter.string(fromByteCount: Int64(mem.total))
        memoryUsageString = "\(usedMemString) / \(totalMemString)"
    }
    
    private func getMemoryUsage() -> (used: Double, total: Double) {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let hostPort = mach_host_self()
        
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &count)
            }
        }
        
        let total = Double(ProcessInfo.processInfo.physicalMemory)
        guard result == KERN_SUCCESS else {
            return (0.0, total)
        }
        
        let pageSize = vm_kernel_page_size
        let active = Double(stats.active_count) * Double(pageSize)
        let wire = Double(stats.wire_count) * Double(pageSize)
        let compressed = Double(stats.compressor_page_count) * Double(pageSize)
        let used = active + wire + compressed
        
        return (used, total)
    }
}
