import SwiftUI
import AppKit

struct DatabaseDaemonItem: Identifiable {
    var id: String { name }
    let name: String
    let port: Int
    let isRunning: Bool
}

class DatabaseStudioManager: ObservableObject {
    @Published var daemons: [DatabaseDaemonItem] = []
    @Published var isScanning = false
    @Published var sqlitePath = ""
    @Published var sqliteTables: [String] = []
    
    init() {
        self.scanDaemons()
    }
    
    func scanDaemons() {
        self.isScanning = true
        Task.detached(priority: .userInitiated) {
            let pgRunning = self.checkPort(5432)
            let mysqlRunning = self.checkPort(3306)
            let redisRunning = self.checkPort(6379)
            let mongoRunning = self.checkPort(27017)
            
            let list = [
                DatabaseDaemonItem(name: "PostgreSQL", port: 5432, isRunning: pgRunning),
                DatabaseDaemonItem(name: "MySQL / MariaDB", port: 3306, isRunning: mysqlRunning),
                DatabaseDaemonItem(name: "Redis Cache", port: 6379, isRunning: redisRunning),
                DatabaseDaemonItem(name: "MongoDB", port: 27017, isRunning: mongoRunning)
            ]
            
            await MainActor.run {
                self.daemons = list
                self.isScanning = false
            }
        }
    }
    
    func openSQLiteFile(path: String) {
        self.sqlitePath = path
        Task.detached(priority: .userInitiated) {
            let output = self.runShellCommand("sqlite3 \"\(path)\" \".tables\"")
            let tables = output.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
            await MainActor.run {
                self.sqliteTables = tables
            }
        }
    }
    
    private func checkPort(_ port: Int) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/nc")
        process.arguments = ["-z", "-w", "1", "127.0.0.1", "\(port)"]
        try? process.run()
        process.waitUntilExit()
        return process.terminationStatus == 0
    }
    
    private func runShellCommand(_ cmd: String) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", cmd]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch { return "" }
    }
}

struct databasestudioview: View {
    @StateObject private var manager = DatabaseStudioManager()
    @State private var selectedTab = "Daemons"
    
    var body: some View {
        VStack(spacing: 0) {
            JuicerFeatureHeader(
                title: "Juicer Database Studio",
                subtitle: "Inspect local Postgres, MySQL, SQLite, and Redis databases, browse keys, and run dumps.",
                icon: "cylinder.split.1x2.fill",
                refreshing: manager.isScanning,
                action: { manager.scanDaemons() }
            )
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            
            Divider()
            
            HStack {
                Picker("", selection: $selectedTab) {
                    Text("Local DB Daemons").tag("Daemons")
                    Text("SQLite Inspector").tag("SQLite")
                }
                .pickerStyle(.segmented)
                .frame(width: 280)
                
                Spacer()
            }
            .padding()
            
            Divider()
            
            if selectedTab == "Daemons" {
                daemonsView()
            } else {
                sqliteView()
            }
        }
        .allowWindowDragAndFit()
    }
    
    @ViewBuilder
    private func daemonsView() -> some View {
        List(manager.daemons) { daemon in
            HStack {
                Circle()
                    .fill(daemon.isRunning ? Color.green : Color.gray)
                    .frame(width: 10, height: 10)
                
                VStack(alignment: .leading) {
                    Text(daemon.name).bold()
                    Text("Port \(daemon.port)").font(.caption.monospaced()).foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(daemon.isRunning ? "Active (Port \(daemon.port))" : "Offline")
                    .font(.caption).bold()
                    .foregroundStyle(daemon.isRunning ? Color.green : Color.secondary)
            }
            .padding(.vertical, 6)
        }
        .listStyle(.inset)
    }
    
    @ViewBuilder
    private func sqliteView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Path to .sqlite or .db file...", text: $manager.sqlitePath)
                    .textFieldStyle(.roundedBorder)
                Button("Choose File...") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = true
                    if panel.runModal() == .OK, let url = panel.url {
                        manager.openSQLiteFile(path: url.path)
                    }
                }
            }
            
            if !manager.sqliteTables.isEmpty {
                Text("Tables Found (\(manager.sqliteTables.count)):").font(.headline)
                List(manager.sqliteTables, id: \.self) { table in
                    HStack {
                        Image(systemName: "tablecells").foregroundStyle(Color.accentColor)
                        Text(table).font(.system(.body, design: .monospaced))
                    }
                }
                .listStyle(.inset)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "externaldrive")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("Select a SQLite database file to inspect schema and tables.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
    }
}
