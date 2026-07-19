import Foundation
import Combine

enum SystemMetricsSupport {
    static func run(_ path: String, _ arguments: [String] = []) -> String? {
        let task = Process(); let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: path); task.arguments = arguments; task.standardOutput = pipe; task.standardError = Pipe()
        do { try task.run(); task.waitUntilExit(); return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) } catch { return nil }
    }
    static func bytes(_ value: UInt64) -> String { ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .binary) }
    static func formatBytes(_ value: UInt64) -> String { bytes(value) }
    static func percent(_ value: Double) -> String { String(format: "%.1f%%", value) }
    static func time(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}
