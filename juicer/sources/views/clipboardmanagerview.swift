import SwiftUI
import AppKit

struct clipboardmanagerview: View {
    @State private var history: [String] = []
    @State private var lastCount = NSPasteboard.general.changeCount
    @State private var timer: Timer?
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Clipboard Manager", subtitle: "Keep a local session history of copied text with one-click restore.", icon: "doc.on.clipboard.fill", refreshing: false, action: poll)
            HStack { Button("Clear History") { history.removeAll() }; Spacer(); Text("Session only").font(.caption).foregroundStyle(.secondary) }
            List(history, id: \.self) { value in HStack { Text(value).lineLimit(2); Spacer(); Button("Copy") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(value, forType: .string) }.buttonStyle(.borderless) } }.listStyle(.inset)
        }.padding(24).onAppear { timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in poll() } }.onDisappear { timer?.invalidate() }
    }
    private func poll() { let pasteboard = NSPasteboard.general; guard pasteboard.changeCount != lastCount else { return }; lastCount = pasteboard.changeCount; if let value = pasteboard.string(forType: .string), !value.isEmpty, value != history.first { history.insert(value, at: 0); history = Array(history.prefix(25)) } }
}
