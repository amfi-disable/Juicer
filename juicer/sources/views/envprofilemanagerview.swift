import SwiftUI
import AppKit

struct envprofilemanagerview: View {
    @StateObject private var manager = EnvProfileManager()
    @State private var maskSecrets = true
    @State private var searchText = ""
    @State private var newProfileName = ""
    @State private var showAddProfileSheet = false
    @State private var newKey = ""
    @State private var newValue = ""
    @State private var isNewSecret = false
    @State private var copiedNotice = ""
    
    var selectedProfile: EnvProfile? {
        manager.profiles.first(where: { $0.id == manager.selectedProfileID })
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $manager.selectedProfileID) {
                Section("Profiles") {
                    ForEach(manager.profiles) { profile in
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundStyle(Color.accentColor)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.name)
                                    .font(.headline)
                                Text("\(profile.variables.count) variables")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tag(profile.id)
                    }
                    .onDelete { indexSet in
                        for idx in indexSet {
                            manager.deleteProfile(id: manager.profiles[idx].id)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddProfileSheet = true }) {
                        Image(systemName: "plus")
                    }
                    .help("Create New Env Profile")
                }
            }
        } detail: {
            if var profile = selectedProfile {
                VStack(spacing: 0) {
                    // Header Bar
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(profile.name)
                                .font(.title2)
                                .bold()
                            if !profile.projectPath.isEmpty {
                                Text(profile.projectPath)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Toggle("Mask Secrets", isOn: $maskSecrets)
                            .toggleStyle(.switch)
                        
                        Button(action: {
                            let str = manager.exportAsEnvString(profile: profile)
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(str, forType: .string)
                            copiedNotice = "Copied .env format!"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copiedNotice = "" }
                        }) {
                            Label("Copy .env", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            let str = manager.exportAsShellExport(profile: profile)
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(str, forType: .string)
                            copiedNotice = "Copied export commands!"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copiedNotice = "" }
                        }) {
                            Label("Copy export", systemImage: "terminal")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
                    
                    if !copiedNotice.isEmpty {
                        HStack {
                            Spacer()
                            Text(copiedNotice)
                                .font(.caption)
                                .bold()
                                .foregroundStyle(.green)
                                .padding(6)
                            Spacer()
                        }
                        .background(Color.green.opacity(0.1))
                    }
                    
                    Divider()
                    
                    // Add Variable Row
                    HStack(spacing: 10) {
                        TextField("KEY_NAME", text: $newKey)
                            .textFieldStyle(.roundedBorder)
                        TextField("Value", text: $newValue)
                            .textFieldStyle(.roundedBorder)
                        Toggle("Secret", isOn: $isNewSecret)
                            .toggleStyle(.checkbox)
                        
                        Button("Add Variable") {
                            guard !newKey.isEmpty else { return }
                            var updatedVars = profile.variables
                            updatedVars.append(EnvVariable(key: newKey, value: newValue, isSecret: isNewSecret))
                            profile.variables = updatedVars
                            manager.updateProfile(profile)
                            newKey = ""
                            newValue = ""
                            isNewSecret = false
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(newKey.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding()
                    
                    Divider()
                    
                    // Variables Table
                    List {
                        ForEach(profile.variables.indices, id: \.self) { idx in
                            let item = profile.variables[idx]
                            HStack {
                                Text(item.key)
                                    .font(.system(.body, design: .monospaced))
                                    .bold()
                                    .frame(width: 200, alignment: .leading)
                                
                                Spacer()
                                
                                Text(maskSecrets && item.isSecret ? "••••••••••••••••" : item.value)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(item.isSecret ? Color.orange : Color.primary)
                                
                                Spacer()
                                
                                if item.isSecret {
                                    Image(systemName: "lock.fill")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                                
                                Button(action: {
                                    var updatedVars = profile.variables
                                    updatedVars.remove(at: idx)
                                    profile.variables = updatedVars
                                    manager.updateProfile(profile)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.inset)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Select or Create an Environment Profile")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showAddProfileSheet) {
            VStack(spacing: 16) {
                Text("New Environment Profile")
                    .font(.headline)
                
                TextField("Profile Name (e.g. Staging Local)", text: $newProfileName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)
                
                HStack {
                    Button("Cancel") { showAddProfileSheet = false }
                    Button("Create") {
                        if !newProfileName.isEmpty {
                            manager.addProfile(name: newProfileName)
                            newProfileName = ""
                            showAddProfileSheet = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
        }
    }
}
