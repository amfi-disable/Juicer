import Foundation
import Combine
import Darwin

enum SystemMetricsSupport {
    /// Runs a system utility without allowing a stalled command to hang the app forever.
    ///
    /// A number of macOS utilities can wait on permission prompts, unavailable
    /// services, or network timeouts. Keep this synchronous API for existing
    /// callers, but bound the wait and keep stderr out of an unread pipe so a
    /// verbose command cannot deadlock while its output buffer fills.
    static func run(_ path: String, _ arguments: [String] = [], timeout: TimeInterval = 30) -> String? {
        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = arguments
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
        } catch {
            return nil
        }

        let deadline = Date().addingTimeInterval(timeout)
        while task.isRunning && Date() < deadline {
            // Pump the current run loop so callers that accidentally invoke a
            // quick command from the main actor remain responsive.
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.01))
        }

        if task.isRunning {
            task.terminate()
            Thread.sleep(forTimeInterval: 0.1)
            if task.isRunning {
                kill(task.processIdentifier, SIGKILL)
            }
            task.waitUntilExit()
            return nil
        }

        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
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
