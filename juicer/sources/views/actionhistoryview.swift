import SwiftUI
import AppKit

struct actionhistoryview: View {
    @ObservedObject private var logger = AppLogger.shared
    @State private var query = ""
    @State private var errorsOnly = false
    @State private var message = ""

    private var filteredLogs: [String] {
        logger.logs.filter { log in
            (!errorsOnly || log.localizedCaseInsensitiveContains("error") || log.localizedCaseInsensitiveContains("failed")) &&
            (query.isEmpty || log.localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            JuicerFeatureHeader(title: "Action History", subtitle: "Review, search, copy, and export Juicer operations and diagnostics.", icon: "clock.arrow.circlepath", refreshing: false, action: {})

            HStack(spacing: 10) {
                TextField("Search history", text: $query)
                    .textFieldStyle(.roundedBorder)
                Toggle("Errors only", isOn: $errorsOnly)
                    .toggleStyle(.checkbox)
                Spacer()
                Button("Copy All") { copy(filteredLogs.joined(separator: "\n")) }
                Button("Export…") { export() }
                    .buttonStyle(.borderedProminent)
                Button("Clear") { logger.clear() }
                    .tint(.red)
            }
            .padding(.bottom, 12)

            if filteredLogs.isEmpty {
                ContentUnavailableView("No matching actions", systemImage: "clock", description: Text("Juicer operations will appear here as they run."))
            } else {
                List(filteredLogs.reversed(), id: \.self) { log in
                    Text(log)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .contextMenu {
                            Button("Copy Entry") { copy(log) }
                        }
                }
                .listStyle(.inset)
            }

            if !message.isEmpty {
                Text(message).font(.caption).foregroundStyle(.secondary).padding(.top, 8)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func copy(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
        message = "Copied to the clipboard."
    }

    private func export() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "juicer-action-history.txt"
        panel.allowedFileTypes = ["txt"]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try filteredLogs.reversed().joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
            message = "Exported (filteredLogs.count) entries."
        } catch {
            message = "Export failed: \(error.localizedDescription)"
        }
    }
}
