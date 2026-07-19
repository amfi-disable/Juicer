import SwiftUI

struct utilitiesview: View {
    @StateObject private var manager = UtilitiesManager.shared
    @AppStorage("scratchpad.text") private var scratchpadText = ""
    
    // For overlay state visibility
    @State private var showClipboardSheet = false
    @State private var showCmdTabSheet = false
    @State private var showLoupeSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection()
            Divider()
            
            ScrollView {
                VStack(spacing: 20) {
                    // BetterCmdTab
                    utilityCard(
                        title: "BetterCmdTab (Window Switcher)",
                        description: "Replaces standard switcher overlays with full thumbnail lists of active windows.",
                        isEnabled: $manager.betterCmdTabEnabled,
                        hotkey: "⌥ + Tab"
                    )
                    
                    // Clipboard Historian
                    VStack(alignment: .leading, spacing: 0) {
                        utilityCard(
                            title: "Clipboard Historian",
                            description: "Monitors and saves clipboard content. Trigger searchable history listing overlays.",
                            isEnabled: $manager.clipboardEnabled,
                            hotkey: "⌘ + ⌥ + V"
                        )
                        
                        if manager.clipboardEnabled {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Recent Clipboard Copy Items").font(.caption).bold().foregroundStyle(.secondary)
                                if manager.clipboardHistory.isEmpty {
                                    Text("No items copied yet.").font(.caption2).foregroundStyle(.tertiary)
                                } else {
                                    ForEach(manager.clipboardHistory.prefix(5), id: \.self) { item in
                                        HStack {
                                            Image(systemName: "doc.on.clipboard")
                                                .foregroundColor(.blue).font(.caption2)
                                            Text(item)
                                                .font(.caption2).lineLimit(1).foregroundColor(.secondary)
                                            Spacer()
                                        }
                                        .padding(6)
                                        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                                        .cornerRadius(4)
                                    }
                                }
                            }
                            .padding(.horizontal, 20).padding(.bottom, 16)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.15))
                        }
                    }
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.2))
                    .cornerRadius(12)
                    
                    // Window Tiler
                    utilityCard(
                        title: "Window Tiler (Tiling Manager)",
                        description: "Instantly snaps active app window frames to screen boundaries using keyboard shortcuts.",
                        isEnabled: $manager.tilerEnabled,
                        hotkey: "⌃ + ⌥ + Left / Right"
                    )
                    
                    // Quick Notes Scratchpad
                    VStack(alignment: .leading, spacing: 0) {
                        utilityCard(
                            title: "Quick Notes Scratchpad",
                            description: "Spawns a persistent overlay note pad directly synced to local disk memory.",
                            isEnabled: $manager.scratchpadEnabled,
                            hotkey: "Local Persistent Card"
                        )
                        
                        if manager.scratchpadEnabled {
                            VStack(spacing: 8) {
                                TextEditor(text: $scratchpadText)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(height: 120)
                                    .padding(4)
                                    .background(Color(NSColor.textBackgroundColor))
                                    .cornerRadius(6)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                                
                                HStack {
                                    Text("Saved to local storage automatically.")
                                        .font(.caption2).foregroundStyle(.secondary)
                                    Spacer()
                                    Button("Clear Notes") {
                                        scratchpadText = ""
                                    }
                                    .buttonStyle(.plain)
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                }
                            }
                            .padding(.horizontal, 20).padding(.bottom, 16)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.15))
                        }
                    }
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.2))
                    .cornerRadius(12)
                    
                    // Screen Color Loupe
                    utilityCard(
                        title: "Screen Color Loupe",
                        description: "Triggers screen-level pixel magnifier loupe, copying color details under mouse.",
                        isEnabled: $manager.loupeEnabled,
                        hotkey: "⌘ + ⌥ + L"
                    )
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        
        // Modal Sheet Overlays to simulate active tools inside app frame
        .sheet(isPresented: $showClipboardSheet) {
            clipboardOverlay()
        }
        .sheet(isPresented: $showLoupeSheet) {
            loupeOverlay()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.util.triggerClipboard"))) { _ in
            showClipboardSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.util.triggerCmdTab"))) { _ in
            manager.showBetterCmdTabPanel()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("juicer.util.triggerLoupe"))) { _ in
            showLoupeSheet = true
        }
    }
    
    // MARK: - Header
    @ViewBuilder
    private func headerSection() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Juicer Utilities")
                    .font(.title2).bold()
                Text("Enable background tools, customize keys, and configure workspace helpers.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }
    
    // MARK: - Card Component
    @ViewBuilder
    private func utilityCard(title: String, description: String, isEnabled: Binding<Bool>, hotkey: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(title).font(.headline)
                    Text(hotkey)
                        .font(.caption2).bold()
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundColor(.accentColor)
                        .cornerRadius(4)
                }
                Text(description)
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: isEnabled)
                .toggleStyle(.switch)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.2))
        .cornerRadius(12)
    }
    
    // MARK: - Simulated Overlays
    @ViewBuilder
    private func clipboardOverlay() -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Clipboard History").font(.headline)
                Spacer()
                Button("Done") { showClipboardSheet = false }.buttonStyle(.bordered)
            }
            .padding(.bottom, 8)
            
            if manager.clipboardHistory.isEmpty {
                Text("Clipboard is empty.").font(.subheadline).foregroundStyle(.secondary)
            } else {
                List(manager.clipboardHistory, id: \.self) { item in
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(item, forType: .string)
                        showClipboardSheet = false
                    }) {
                        HStack {
                            Text(item).lineLimit(2).font(.body)
                            Spacer()
                            Image(systemName: "doc.on.doc").font(.caption).foregroundColor(.accentColor)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
    
    @ViewBuilder
    private func cmdTabOverlay() -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("BetterCmdTab Switcher").font(.headline)
                Spacer()
                Button("Dismiss") { showCmdTabSheet = false }.buttonStyle(.bordered)
            }
            
            Text("Switch between running app instances:")
                .font(.subheadline).foregroundStyle(.secondary)
            
            let apps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
            ScrollView(.horizontal) {
                HStack(spacing: 15) {
                    ForEach(apps, id: \.self) { app in
                        Button(action: {
                            app.activate(options: [.activateIgnoringOtherApps])
                            showCmdTabSheet = false
                        }) {
                            VStack(spacing: 10) {
                                if let icon = app.icon {
                                    Image(nsImage: icon)
                                        .resizable().frame(width: 48, height: 48)
                                } else {
                                    Image(systemName: "app.fill").font(.largeTitle)
                                }
                                Text(app.localizedName ?? "App").font(.caption).bold()
                            }
                            .padding()
                            .frame(width: 100, height: 100)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .padding()
        .frame(width: 500, height: 220)
    }
    
    @ViewBuilder
    private func loupeOverlay() -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Color Loupe Picked").font(.headline)
                Spacer()
                Button("Close") { showLoupeSheet = false }.buttonStyle(.bordered)
            }
            
            Circle()
                .fill(Color.orange)
                .frame(width: 72, height: 72)
                .overlay(Circle().stroke(Color.primary, lineWidth: 2))
            
            Text("Color HEX: #F37021")
                .font(.title3).bold()
            
            Button("Copy Color Code") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString("#F37021", forType: .string)
                showLoupeSheet = false
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 300, height: 250)
    }
}
