import SwiftUI

struct menubarmonitorview: View {
    @State private var disk = "Loading…"
    @State private var memory = "Loading…"
    @State private var timer: Timer?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Juicer Status", systemImage: "waveform.path.ecg")
                .font(.headline)
            Divider()
            Label(disk, systemImage: "internaldrive")
            Label(memory, systemImage: "memorychip")
            Divider()
            Button("Open Juicer Dashboard") {
                NSApp.activate(ignoringOtherApps: true)
                NotificationCenter.default.post(name: NSNotification.Name("juicer.nav.dashboard"), object: nil)
            }
            Button("Refresh") { update() }
        }
        .padding(14)
        .frame(width: 260)
        .onAppear {
            update()
            timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in update() }
        }
        .onDisappear { timer?.invalidate() }
    }

    private func update() {
        if let values = try? FileManager.default.attributesOfFileSystem(forPath: "/"),
           let total = values[.systemSize] as? Int64,
           let free = values[.systemFreeSize] as? Int64 {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            disk = "Disk: \(formatter.string(fromByteCount: total - free)) / \(formatter.string(fromByteCount: total))"
        }

        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return }
        let used = Double(stats.active_count + stats.wire_count + stats.compressor_page_count) * Double(vm_kernel_page_size)
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        memory = "Memory: \(formatter.string(fromByteCount: Int64(used))) / \(formatter.string(fromByteCount: Int64(ProcessInfo.processInfo.physicalMemory)))"
    }
}
