import SwiftUI
import AppKit

struct workflowcenterview: View {
    @StateObject private var manager = workflowtaskmanager.shared
    @AppStorage("juicer.workflow.dryRun") private var dryRun = false
    @AppStorage("juicer.workflow.notifications") private var notifications = true
    @AppStorage("juicer.workflow.customPaths") private var customPaths = ""
    @State private var pathInput = ""
    @State private var copied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                JuicerFeatureHeader(title: "Workflow Center", subtitle: "Queue safe, read-only diagnostics inspired by modular monitors, preview-first cleaners, and scriptable utilities.", icon: "list.bullet.clipboard", refreshing: manager.isRunning) {
                    manager.enqueueAll()
                }

                controls
                presets
                taskList
                scanScope
                reportActions
            }
            .padding(24)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var controls: some View {
        JuicerFeatureList(title: "Run controls") {
            HStack {
                Toggle("Preview commands before running", isOn: $dryRun)
                Spacer()
                Toggle("Completion notifications", isOn: $notifications)
            }
            Text("Diagnostics never modify files. Preview mode records the selected checks without launching a process.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Label(manager.isPaused ? "Queue paused" : (manager.isRunning ? "A task is running" : "Queue ready"), systemImage: manager.isPaused ? "pause.circle" : (manager.isRunning ? "play.circle" : "checkmark.circle"))
                    .foregroundStyle(manager.isPaused ? .orange : .secondary)
                Spacer()
                Button(manager.isPaused ? "Resume queue" : "Pause queue") { manager.togglePause() }
                    .buttonStyle(.bordered)
                    .disabled(!manager.isRunning && manager.tasks.isEmpty)
                Button("Clear finished", role: .destructive) { manager.clearFinished() }
                    .buttonStyle(.bordered)
            }
        }
    }

    private var presets: some View {
        JuicerFeatureList(title: "Diagnostic presets") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 10)], spacing: 10) {
                ForEach(WorkflowTaskKind.allCases) { kind in
                    Button {
                        if dryRun {
                            AppLogger.shared.log("Previewed workflow: \(kind.title)")
                        } else {
                            if kind == .diskHealth && !savedPaths.isEmpty {
                                manager.enqueueDiskHealth(paths: savedPaths)
                            } else {
                                manager.enqueue(kind)
                            }
                            if notifications { NotificationManager.shared.sendNotification(title: "Workflow queued", body: kind.title) }
                        }
                    } label: {
                        Label(kind.title, systemImage: kind.icon)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                }
            }
            Button {
                if dryRun {
                    AppLogger.shared.log("Previewed complete system workflow")
                } else {
                    manager.enqueueAll()
                }
            } label: {
                Label("Run complete health check", systemImage: "checkmark.seal")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var taskList: some View {
        JuicerFeatureList(title: "Queue and history") {
            if manager.tasks.isEmpty {
                ContentUnavailableView("No workflows yet", systemImage: "tray", description: Text("Choose a diagnostic preset above to start a local report."))
            } else {
                ForEach(manager.tasks) { task in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label(task.kind.title, systemImage: task.kind.icon).font(.headline)
                            Spacer()
                            Text(task.state.title).font(.caption).foregroundStyle(task.state == .failed ? .red : .secondary)
                            if task.state == .failed { Button("Retry") { manager.retry(task) }.buttonStyle(.link) }
                            if task.state == .queued || task.state == .running { Button("Cancel") { manager.cancel(task) }.buttonStyle(.link) }
                            if task.state != .running { Button { manager.remove(task) } label: { Image(systemName: "trash") }.buttonStyle(.borderless) }
                        }
                        if !task.output.isEmpty {
                            Text(task.output)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .lineLimit(5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .background(Color.black.opacity(0.08), in: RoundedRectangle(cornerRadius: 7))
                        }
                    }
                    .padding(.vertical, 5)
                    Divider()
                }
            }
        }
    }

    private var scanScope: some View {
        JuicerFeatureList(title: "Scan scope") {
            HStack {
                TextField("Optional paths, separated by commas", text: $pathInput)
                    .textFieldStyle(.roundedBorder)
                Button("Add path") {
                    let clean = pathInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !clean.isEmpty else { return }
                    let values = customPaths.split(separator: ",").map(String.init) + [clean]
                    customPaths = Array(Set(values)).sorted().joined(separator: ",")
                    pathInput = ""
                }
                .buttonStyle(.bordered)
            }
            if customPaths.isEmpty {
                Text("No custom paths saved. Built-in checks use standard macOS locations.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(customPaths.split(separator: ",").map(String.init), id: \.self) { path in
                    Label(path, systemImage: "folder")
                        .font(.caption)
                        .textSelection(.enabled)
                }
            }
        }
    }

    private var savedPaths: [String] {
        customPaths.split(separator: ",").map(String.init)
    }

    private var reportActions: some View {
        HStack {
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(manager.reportText(), forType: .string)
                copied = true
            } label: {
                Label(copied ? "Copied" : "Copy report", systemImage: copied ? "checkmark" : "doc.on.doc")
            }
            .buttonStyle(.bordered)
            Button("Export report…") { exportReport() }
                .buttonStyle(.borderedProminent)
        }
    }

    private func exportReport() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "juicer-workflow-report.txt"
        panel.allowedContentTypes = [.plainText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try manager.reportText().write(to: url, atomically: true, encoding: .utf8)
            NSWorkspace.shared.activateFileViewerSelecting([url])
            AppLogger.shared.log("Exported workflow report")
        } catch {
            AppLogger.shared.log("Workflow report export failed: \(error.localizedDescription)")
        }
    }
}
