import SwiftUI
import AppKit

struct logstreamview: View {
    @StateObject private var manager = LogStreamManager()
    @State private var searchText = ""
    
    var filteredEntries: [LogEntry] {
        if searchText.isEmpty { return manager.logEntries }
        return manager.logEntries.filter { $0.message.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Real-Time Unified Log Stream")
                        .font(.title2)
                        .bold()
                    Text("Stream and filter macOS system and application logs (os_log) live.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    if manager.isStreaming {
                        manager.stopStreaming()
                    } else {
                        manager.startStreaming()
                    }
                }) {
                    Label(manager.isStreaming ? "Stop Stream" : "Start Live Stream", systemImage: manager.isStreaming ? "stop.fill" : "play.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            
            Divider()
            
            // Search & Filter Toolbar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search logs...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)
                
                Spacer()
                
                Text("\(filteredEntries.count) entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Button("Clear Logs") {
                    manager.logEntries = []
                }
                .buttonStyle(.bordered)
            }
            .padding()
            
            Divider()
            
            // Log Stream Table
            ScrollViewReader { proxy in
                List(filteredEntries) { entry in
                    HStack(alignment: .top, spacing: 10) {
                        Text(entry.level)
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(entry.level == "Error" || entry.level == "Fault" ? Color.red.opacity(0.2) : Color.blue.opacity(0.1))
                            .foregroundStyle(entry.level == "Error" || entry.level == "Fault" ? Color.red : Color.blue)
                            .cornerRadius(4)
                        
                        Text(entry.message)
                            .font(.system(.caption, design: .monospaced))
                            .lineLimit(3)
                        
                        Spacer()
                    }
                    .padding(.vertical, 2)
                    .id(entry.id)
                }
                .listStyle(.inset)
                .onChange(of: manager.logEntries.count) { _ in
                    if let last = manager.logEntries.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
        .onDisappear {
            manager.stopStreaming()
        }
    }
}
