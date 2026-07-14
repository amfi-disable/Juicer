import SwiftUI
import UniformTypeIdentifiers

struct quarantinestripperview: View {
    @StateObject private var stripper = QuarantineStripper()
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection()
            
            // Drag and drop zone
            dragAndDropZone()
                .padding()
            
            // Cleaned list header
            HStack {
                Text("Processed Files History")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                if !stripper.processedItems.isEmpty {
                    Button("Clear History") {
                        stripper.processedItems.removeAll()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            // History list
            if stripper.processedItems.isEmpty {
                emptyHistoryView()
            } else {
                historyList()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.underlyingWindowBackgroundColor))
    }
    
    // MARK: - Header UI
    @ViewBuilder
    private func headerSection() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Gatekeeper / Quarantine Stripper")
                    .font(.title2)
                    .bold()
                Text("Strip the Gatekeeper quarantine attribute from downloaded scripts, files, or applications recursively.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }
    
    // MARK: - Drag and Drop Zone UI
    @ViewBuilder
    private func dragAndDropZone() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(isDragging ? Color.accentColor.opacity(0.12) : Color(NSColor.controlBackgroundColor).opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            isDragging ? Color.accentColor : Color.secondary.opacity(0.3),
                            style: StrokeStyle(lineWidth: 2, dash: isDragging ? [] : [6])
                        )
                )
            
            VStack(spacing: 16) {
                if stripper.isProcessing {
                    ProgressView("Stripping quarantine attributes...")
                        .progressViewStyle(.circular)
                } else {
                    Image(systemName: "shield.slash.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(isDragging ? Color.accentColor : Color.secondary)
                        .scaleEffect(isDragging ? 1.1 : 1.0)
                        .animation(.spring(), value: isDragging)
                    
                    VStack(spacing: 4) {
                        Text("Drop Quarantined Files or Apps")
                            .font(.headline)
                        Text("Recursively clears the 'com.apple.quarantine' attribute")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Button("Select Files Manually...") {
                        selectFilesManually()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .frame(height: 180)
        .onDrop(of: [.item], isTargeted: $isDragging) { providers in
            var urls: [URL] = []
            let group = DispatchGroup()
            
            for provider in providers {
                group.enter()
                _ = provider.loadObject(ofClass: URL.self) { url, error in
                    if let url = url {
                        urls.append(url)
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                if !urls.isEmpty {
                    stripper.stripQuarantine(for: urls)
                }
            }
            
            return true
        }
    }
    
    // MARK: - Empty State UI
    @ViewBuilder
    private func emptyHistoryView() -> some View {
        VStack {
            Spacer()
            Image(systemName: "clock")
                .font(.system(size: 32))
                .foregroundStyle(.secondary.opacity(0.6))
                .padding(.bottom, 6)
            Text("No files processed yet.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - History List UI
    @ViewBuilder
    private func historyList() -> some View {
        List(stripper.processedItems) { item in
            HStack {
                Image(systemName: item.status == "Stripped" ? "lock.open.fill" : (item.status == "Failed" ? "exclamationmark.shield.fill" : "shield.fill"))
                    .foregroundStyle(item.status == "Stripped" ? .green : (item.status == "Failed" ? .red : .secondary))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.body)
                        .bold()
                    Text(item.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                Spacer()
                
                statusBadge(status: item.status)
            }
            .padding(.vertical, 4)
        }
        .listStyle(.inset)
    }
    
    @ViewBuilder
    private func statusBadge(status: String) -> some View {
        let color: Color
        let bgColor: Color
        
        switch status {
        case "Stripped":
            color = .green
            bgColor = .green.opacity(0.15)
        case "Failed":
            color = .red
            bgColor = .red.opacity(0.15)
        default:
            color = .secondary
            bgColor = .secondary.opacity(0.15)
        }
        
        Text(status)
            .font(.caption2)
            .bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(bgColor)
            .foregroundColor(color)
            .cornerRadius(8)
    }
    
    // MARK: - Actions
    private func selectFilesManually() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.prompt = "Strip Quarantine"
        
        if panel.runModal() == .OK {
            stripper.stripQuarantine(for: panel.urls)
        }
    }
}
