import SwiftUI
import AppKit

struct networkbandwidthmanagerview: View {
    @StateObject private var manager = NetworkBandwidthManager()
    @State private var searchText = ""
    
    var filteredStats: [ProcessNetworkStat] {
        if searchText.isEmpty {
            return manager.processStats
        }
        return manager.processStats.filter {
            $0.processName.localizedCaseInsensitiveContains(searchText) ||
            String($0.pid).contains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Per-Process Network Bandwidth Inspector")
                        .font(.title2)
                        .bold()
                    Text("Monitor real-time network throughput (download & upload) per running process.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 12) {
                        Label(String(format: "↓ %.1f KB/s", manager.totalDownloadSpeed), systemImage: "arrow.down.circle.fill")
                            .foregroundStyle(.green)
                            .font(.headline)
                        Label(String(format: "↑ %.1f KB/s", manager.totalUploadSpeed), systemImage: "arrow.up.circle.fill")
                            .foregroundStyle(.blue)
                            .font(.headline)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            
            Divider()
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search Process Name or PID...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                
                Spacer()
                
                Button(action: {
                    if manager.isMonitoring {
                        manager.stopMonitoring()
                    } else {
                        manager.startMonitoring()
                    }
                }) {
                    Label(manager.isMonitoring ? "Pause" : "Resume", systemImage: manager.isMonitoring ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.bordered)
            }
            .padding()
            
            Divider()
            
            // Stats List
            List {
                ForEach(filteredStats) { stat in
                    HStack {
                        Image(systemName: "network")
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stat.processName)
                                .font(.headline)
                            Text("PID: \(stat.pid)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 20) {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(String(format: "↓ %.1f KB/s", stat.rateIn))
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(stat.rateIn > 0 ? .green : .secondary)
                                Text("Total: \(formattedBytes(stat.bytesIn))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 120, alignment: .trailing)
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(String(format: "↑ %.1f KB/s", stat.rateOut))
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(stat.rateOut > 0 ? .blue : .secondary)
                                Text("Total: \(formattedBytes(stat.bytesOut))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 120, alignment: .trailing)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.inset)
        }
        .onAppear {
            manager.startMonitoring()
        }
        .onDisappear {
            manager.stopMonitoring()
        }
    }
    
    private func formattedBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
