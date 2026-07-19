import SwiftUI
import AppKit

struct scriptpluginsview: View {
    @State private var folder = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/Juicer/Plugins")
    @State private var scripts: [URL] = []
    @State private var output = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Script Plugins", subtitle: "Run trusted local scripts from a watched, user-selected folder.", icon: "puzzlepiece.extension", refreshing: false, action: refresh)
            HStack {
                Text(folder.path).font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                Spacer()
                Button("Choose Folder…") { chooseFolder() }
                Button("Open Folder") { NSWorkspace.shared.open(folder) }
            }
            Text("Scripts run only when you press Run. Review their contents before executing them.")
                .font(.caption).foregroundStyle(.orange)
            if scripts.isEmpty {
                ContentUnavailableView("No Plugins", systemImage: "puzzlepiece.extension", description: Text("Add executable .sh, .command, or .zsh files to this folder."))
            } else {
                List(scripts, id: \.self) { script in
                    HStack {
                        Image(systemName: "terminal")
                        Text(script.lastPathComponent)
                        Spacer()
                        Button("Run") { run(script) }.buttonStyle(.borderedProminent).controlSize(.small)
                    }
                }
                .listStyle(.inset)
            }
            if !output.isEmpty {
                ScrollView { Text(output).font(.system(.caption, design: .monospaced)).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading) }
                    .frame(minHeight: 80).padding(10).background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(24)
        .onAppear(perform: refresh)
    }

    private func refresh() {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        scripts = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil))?.filter { ["sh", "command", "zsh"].contains($0.pathExtension.lowercased()) }.sorted { $0.lastPathComponent < $1.lastPathComponent } ?? []
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url { folder = url; refresh() }
    }

    private func run(_ script: URL) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = [script.path]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            process.waitUntilExit()
            output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "No output."
        } catch { output = error.localizedDescription }
    }
}
