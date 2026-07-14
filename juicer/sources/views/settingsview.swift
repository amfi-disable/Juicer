import SwiftUI

struct settingsview: View {
    @AppStorage("juicer.settings.killForceful") private var killForceful = false
    @AppStorage("juicer.settings.defaultToDevPorts") private var defaultToDevPorts = true
    @AppStorage("juicer.settings.showProcessArgs") private var showProcessArgs = true
    
    var body: some View {
        TabView {
            Form {
                Section(header: Text("Network Port Settings").bold()) {
                    Toggle("Force-Kill Processes (SIGKILL / kill -9)", isOn: $killForceful)
                        .help("If enabled, uses SIGKILL signal to immediately force-terminate processes. If disabled, uses SIGTERM to request graceful shut down.")
                    
                    Toggle("Default to Dev Ports Only", isOn: $defaultToDevPorts)
                        .help("If enabled, filters port listener automatically to show only common local development ports.")
                    
                    Toggle("Show Full Process Arguments", isOn: $showProcessArgs)
                        .help("Display command line launch arguments for processes holding ports.")
                }
            }
            .tabItem {
                Label("General", systemImage: "gearshape")
            }
            .padding()
            
            VStack(spacing: 12) {
                Image("AppIcon")
                    .resizable()
                    .frame(width: 64, height: 64)
                    .cornerRadius(12)
                Text("juicer")
                    .font(.title)
                    .bold()
                Text("Version 1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("© 2026 amfi-disable. All rights reserved.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
            .padding()
        }
        .frame(width: 480, height: 260)
    }
}
