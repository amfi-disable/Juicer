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
                stepRow(num: "3", text: "Find 'juicer' (or click '+' and select it) and toggle it ON.")
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

                Button("Verify & Continue") {
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
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
    }

    private func verifyAccess() {
        let hasAccess = onboardingview.checkFullDiskAccess()
        withAnimation {
            if hasAccess {
                isAccessGranted = true
            } else {
                checkFailed = true
            }
        }
    }

    // Helper checking access by attempting to read folder that requires Full Disk Access
    static func checkFullDiskAccess() -> Bool {
        let path = NSHomeDirectory() + "/Library/Safari"
        do {
            _ = try FileManager.default.contentsOfDirectory(atPath: path)
            return true
        } catch {
            return false
        }
    }
}
