import SwiftUI
import AppKit

struct applanguagestripperview: View {
    @StateObject private var manager = AppLanguageStripperManager()
    @State private var searchText = ""
    @State private var showConfirmAlert = false
    
    var filteredBundles: [AppLanguageBundle] {
        if searchText.isEmpty { return manager.foundBundles }
        return manager.foundBundles.filter {
            $0.appName.localizedCaseInsensitiveContains(searchText) ||
            $0.languageCode.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var selectedSize: Int64 {
        manager.foundBundles.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("App Language Asset Stripper")
                        .font(.title2)
                        .bold()
                    Text("Strip unused localization files (.lproj) from installed applications to reclaim disk space.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if manager.isScanning {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button(action: { manager.scanAppLanguages() }) {
                        Label("Scan Apps", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            
            Divider()
            
            // Search & Action Toolbar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search App Name or Language...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 250)
                
                Spacer()
                
                Text("Selected: \(ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file))")
                    .font(.callout)
                    .bold()
                    .foregroundStyle(.secondary)
                
                Button(action: { showConfirmAlert = true }) {
                    Label("Strip Selected", systemImage: "scissors")
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedSize == 0 || manager.isStripping)
            }
            .padding()
            
            Divider()
            
            // Results List
            if manager.isScanning {
                VStack(spacing: 12) {
                    ProgressView("Scanning Applications for unused language files...")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if manager.foundBundles.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    Text("No unused language assets found!")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredBundles.indices, id: \.self) { idx in
                        let bundle = filteredBundles[idx]
                        HStack {
                            Toggle("", isOn: Binding(
                                get: { bundle.isSelected },
                                set: { val in
                                    if let origIdx = manager.foundBundles.firstIndex(where: { $0.id == bundle.id }) {
                                        manager.foundBundles[origIdx].isSelected = val
                                    }
                                }
                            ))
                            .labelsHidden()
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(bundle.appName)
                                    .font(.headline)
                                Text("Language: \(bundle.languageCode).lproj")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(ByteCountFormatter.string(fromByteCount: bundle.size, countStyle: .file))
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.inset)
            }
        }
        .onAppear {
            manager.scanAppLanguages()
        }
        .alert("Strip Selected Language Files?", isPresented: $showConfirmAlert) {
            Button("Strip Language Files", role: .destructive) {
                manager.stripSelectedLanguages { _ in }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove the selected .lproj localization directories from your applications. Are you sure you want to proceed?")
        }
    }
}
