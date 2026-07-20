import SwiftUI
import AppKit

struct onboardingview: View {
    @Binding var isAccessGranted: Bool
    @State private var checkFailed = false
    @State private var animateIcon = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Header Icon & Title
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 90, height: 90)
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.accentColor)
                        .scaleEffect(animateIcon ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animateIcon)
                }
                .onAppear { animateIcon = true }

                Text("Companion Setup: Full Disk Access")
                    .font(.title).bold()
                
                Text("Juicer is your macOS developer companion. To clean caches, remove orphan folders, edit service agents, and optimize directories, it requires Full Disk Access.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 550)
            }

            // Steps layout
            VStack(alignment: .leading, spacing: 14) {
                stepRow(num: "1", text: "Click the button below to open the macOS Privacy settings.")
                stepRow(num: "2", text: "Locate 'Full Disk Access' in the list.")
                stepRow(num: "3", text: "Find 'Juicer' (or click '+' and select it) and toggle it ON.")
                stepRow(num: "4", text: "Once enabled, click the 'Verify & Continue' button below.")
            }
            .padding()
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(12)
            .frame(maxWidth: 550)

            if checkFailed {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.octagon.fill").foregroundColor(.red)
                    Text("Full Disk Access not detected yet. Please verify it is toggled on in System Settings.")
                        .font(.subheadline).foregroundColor(.red)
                }
                .transition(.opacity)
            }

            // Action Buttons
            VStack(spacing: 12) {
                Button(action: openSystemSettings) {
                    HStack {
                        Image(systemName: "arrow.up.forward.square.fill")
                        Text("Open System Settings")
                    }
                    .frame(width: 260).padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)

                Button("Continue to Juicer") {
                    verifyAccess()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.defaultAction)
            }

            Spacer()
        }
        .padding(40)
        .frame(minWidth: 800, minHeight: 600)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func stepRow(num: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(num)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.accentColor))
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") else { return }
        NSWorkspace.shared.open(url)
    }

    private func verifyAccess() {
        withAnimation {
            isAccessGranted = true
        }
    }

    // Helper checking access by attempting to read folder that requires Full Disk Access
    static func checkFullDiskAccess() -> Bool {
        let paths = [
            NSHomeDirectory() + "/Library/Safari",
            "/Library/Application Support/com.apple.TCC"
        ]
        
        for path in paths {
            do {
                _ = try FileManager.default.contentsOfDirectory(atPath: path)
                return true
            } catch {
                let nsError = error as NSError
                // Cocoa error 257 = File read no permission
                // POSIX error 13 = Permission denied (EACCES)
                // POSIX error 1 = Operation not permitted (EPERM)
                if nsError.code == 257 || (nsError.domain == NSPOSIXErrorDomain && (nsError.code == 13 || nsError.code == 1)) {
                    return false
                }
            }
        }
        return true
    }
}
