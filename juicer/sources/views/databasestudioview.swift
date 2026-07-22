import SwiftUI
import AppKit

struct databasestudioview: View {
    @StateObject private var manager = DatabaseManager.shared
    @State private var selectedTab = 0
    @State private var dumpDbName = "app_development"
    @State private var dumpCommandOutput = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Banner
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: [.indigo, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 52, height: 52)
                    Image(systemName: "cylinder.split.1x2.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Juicer Database Studio")
                            .font(.title2).bold()
                        
                        HStack(spacing: 5) {
                            Circle()
                                .fill(manager.activeCount > 0 ? Color.green : Color.orange)
                                .frame(width: 7, height: 7)
                            Text("\(manager.activeCount) DAEMONS LISTENING")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(manager.activeCount > 0 ? .green : .orange)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background((manager.activeCount > 0 ? Color.green : Color.orange).opacity(0.14), in: Capsule())
                    }
                    
                    Text("Local Postgres, MySQL, SQLite, and Redis database status, key inspector, and SQL dump tools")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: { manager.refreshAll() }) {
                    Label("Scan Ports", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
                .disabled(manager.isRefreshing)
            }
            .padding(20)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Picker Tab Bar
            HStack {
                Picker("", selection: $selectedTab) {
                    Text("Daemon Ports (\(manager.daemons.count))").tag(0)
                    Text("SQLite Inspector (\(manager.sqliteFiles.count))").tag(1)
                    Text("Redis Viewer").tag(2)
                    Text("SQL Dump & Backup").tag(3)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 580)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Tab Content
            switch selectedTab {
            case 0:
                daemonsTabView()
            case 1:
                sqliteTabView()
            case 2:
                redisTabView()
            default:
                dumpTabView()
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            manager.refreshAll()
        }
    }
    
    // MARK: - Tab 1: Database Daemons
    @ViewBuilder
    private func daemonsTabView() -> some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(manager.daemons) { db in
                    HStack(spacing: 14) {
                        Image(systemName: db.iconName)
                            .font(.title2)
                            .foregroundColor(db.isRunning ? .green : .secondary)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(db.name)
                                    .font(.headline.bold())
                                Spacer()
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(db.isRunning ? Color.green : Color.red)
                                        .frame(width: 6, height: 6)
                                    Text(db.isRunning ? "ONLINE" : "OFFLINE")
                                        .font(.caption2.bold())
                                        .foregroundStyle(db.isRunning ? .green : .red)
                                }
                            }
                            Text("Port: \(db.port)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(16)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.secondary.opacity(0.12), lineWidth: 1))
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Tab 2: SQLite Inspector
    @ViewBuilder
    private func sqliteTabView() -> some View {
        if manager.sqliteFiles.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "externaldrive")
                    .font(.system(size: 44))
                    .foregroundColor(.secondary)
                Text("No Local SQLite Files Discovered")
                    .font(.headline)
                Text("Scan completed across user Library and Projects folders.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(manager.sqliteFiles) { file in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(file.name)
                                    .font(.headline.bold())
                                Text(file.path)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(file.size)
                                .font(.caption.bold())
                                .foregroundColor(.indigo)
                            
                            Button("Reveal") {
                                NSWorkspace.shared.selectFile(file.path, inFileViewerRootedAtPath: "")
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(14)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(20)
            }
        }
    }
    
    // MARK: - Tab 3: Redis Viewer
    @ViewBuilder
    private func redisTabView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "bolt.horizontal.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            Text("Redis Cache Inspector")
                .font(.title2).bold()
            Text("Inspect active key-value store items on port `6379`.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button("Run `redis-cli ping`") {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/redis-cli")
                process.arguments = ["ping"]
                try? process.run()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
    }
    
    // MARK: - Tab 4: SQL Dump & Backup
    @ViewBuilder
    private func dumpTabView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SQL Database Backup Generator")
                .font(.title3.bold())
            Text("Generate automated backup dump shell commands for local databases.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                TextField("Database Name", text: $dumpDbName)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 260)
                
                Button("Generate pg_dump Command") {
                    dumpCommandOutput = "pg_dump -U postgres -h localhost \(dumpDbName) > ~/Desktop/\(dumpDbName)_backup.sql"
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
                
                Button("Generate mysqldump") {
                    dumpCommandOutput = "mysqldump -u root -p \(dumpDbName) > ~/Desktop/\(dumpDbName)_backup.sql"
                }
                .buttonStyle(.bordered)
            }
            
            if !dumpCommandOutput.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Generated Shell Command:")
                        .font(.caption.bold())
                    Text(dumpCommandOutput)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.green)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                    
                    Button("Copy Command") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(dumpCommandOutput, forType: .string)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 10)
            }
            
            Spacer()
        }
        .padding(20)
    }
}
