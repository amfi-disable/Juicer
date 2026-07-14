import SwiftUI

struct systemtweakerview: View {
    @StateObject private var tweaker = SystemTweaker()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hidden System Tweaker")
                        .font(.title2)
                        .bold()
                    Text("Customize advanced macOS preferences beyond standard system limits.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                // Keyboard Repeat Settings Card
                tweakSectionCard(title: "Keyboard Speed", systemImage: "keyboard") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Fine-tune keyboard inputs. Note: Lower values mean faster response.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Key Repeat Rate:")
                                    .bold()
                                Spacer()
                                Text("\(tweaker.keyRepeat) (Lower is faster)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: Binding(
                                get: { Double(tweaker.keyRepeat) },
                                set: { tweaker.keyRepeat = Int($0) }
                            ), in: 1...120, step: 1)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Delay Until Repeat:")
                                    .bold()
                                Spacer()
                                Text("\(tweaker.initialKeyRepeat) (Lower is shorter)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: Binding(
                                get: { Double(tweaker.initialKeyRepeat) },
                                set: { tweaker.initialKeyRepeat = Int($0) }
                            ), in: 5...120, step: 1)
                        }
                        
                        HStack {
                            Spacer()
                            Button("Apply Keyboard Tweaks") {
                                tweaker.saveKeyboardSettings()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
                
                // Finder Settings Card
                tweakSectionCard(title: "Finder Preferences", systemImage: "macwindow") {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle("Show Hidden Files & Directories", isOn: $tweaker.showHiddenFiles)
                        Toggle("Show Path Bar in Finder Windows", isOn: $tweaker.showPathBar)
                        Toggle("Disable Window Zoom and Resize Animations", isOn: $tweaker.disableFinderAnimations)
                        
                        HStack {
                            Spacer()
                            Button("Apply Finder Tweaks") {
                                tweaker.saveFinderSettings()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
                
                // Dock Preferences Card
                tweakSectionCard(title: "Dock Autohide Speeds", systemImage: "dock.rectangle") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Customize auto-hide slide delay and animation speeds. Set to 0.0 for instant response.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Autohide Delay:")
                                    .bold()
                                Spacer()
                                Text(String(format: "%.2fs", tweaker.dockAutohideDelay))
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: $tweaker.dockAutohideDelay, in: 0.0...2.0, step: 0.05)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Animation Slide Duration:")
                                    .bold()
                                Spacer()
                                Text(String(format: "%.2fs", tweaker.dockAutohideTimeModifier))
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: $tweaker.dockAutohideTimeModifier, in: 0.0...2.0, step: 0.05)
                        }
                        
                        HStack {
                            Spacer()
                            Button("Apply Dock Tweaks") {
                                tweaker.saveDockSettings()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
                
                // Screenshots Card
                tweakSectionCard(title: "Screenshot Captures", systemImage: "camera") {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Save Folder Path:")
                                    .bold()
                                Spacer()
                                Button("Choose...") {
                                    selectScreenshotFolder()
                                }
                                .buttonStyle(.bordered)
                            }
                            TextField("Path (e.g. ~/Desktop)", text: $tweaker.screenshotLocation)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        Toggle("Disable Shadow on Window Captures", isOn: $tweaker.screenshotDisableShadow)
                        
                        Picker("File Format Output:", text: $tweaker.screenshotFormat) {
                            Text("PNG").tag("png")
                            Text("JPG").tag("jpg")
                            Text("PDF").tag("pdf")
                            Text("TIFF").tag("tiff")
                        }
                        .pickerStyle(.segmented)
                        
                        HStack {
                            Spacer()
                            Button("Apply Screenshot Tweaks") {
                                tweaker.saveScreenshotSettings()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
            .padding(30)
        }
        .background(Color(NSColor.underlyingWindowBackgroundColor))
        .onAppear {
            tweaker.loadAllPreferences()
        }
    }
    
    // MARK: - Reusable Card Component
    @ViewBuilder
    private func tweakSectionCard<Content: View>(title: String, systemImage: String, @ViewBuilder content: () -> Content) -> View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)
                Text(title)
                    .font(.headline)
                    .bold()
            }
            
            content()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Actions
    private func selectScreenshotFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose Folder"
        
        if panel.runModal() == .OK, let url = panel.url {
            tweaker.screenshotLocation = url.path
        }
    }
}
