import SwiftUI
import AppKit
import LocalAuthentication

struct applockerview: View { @State private var apps: [URL] = []; @State private var message = ""; var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "App Locker", subtitle: "Maintain a protected app list and require Touch ID or a password to unlock it.", icon: "lock.app.dashed", refreshing: false, action: {}) ; HStack { Button("Add Application…") { add() }; Button("Authenticate") { authenticate() }.buttonStyle(.borderedProminent) }; List(apps, id: \.self) { Text($0.lastPathComponent) }.listStyle(.inset); Text(message).font(.caption).foregroundStyle(.secondary) }.padding(24) }
    private func add() { let panel = NSOpenPanel(); panel.allowedFileTypes = ["app"]; if panel.runModal() == .OK, let url = panel.url { apps.append(url) } }
    private func authenticate() { let context = LAContext(); context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock Juicer App Locker") { success, error in DispatchQueue.main.async { message = success ? "Authenticated for the protected app list." : (error?.localizedDescription ?? "Authentication failed.") } } }
}
