import SwiftUI
import AppKit

struct sandboxinspectorview: View {
    @State private var app: URL?
    @State private var output = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Application Sandbox Inspector", subtitle: "Inspect entitlements embedded in a signed macOS application.", icon: "shippingbox", refreshing: false, action: {})
            HStack { Button("Choose App…") { choose() }; Spacer() }
            if let app { Text(app.path).font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle) }
            ScrollView { Text(output.isEmpty ? "Choose an application to inspect its entitlements." : output).font(.system(.caption, design: .monospaced)).frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled) }
            Spacer()
        }.padding(24)
    }
    private func choose() { let panel = NSOpenPanel(); panel.allowedFileTypes = ["app"]; guard panel.runModal() == .OK, let url = panel.url else { return }; app = url; DispatchQueue.global().async { let result = SystemMetricsSupport.run("/usr/bin/codesign", ["-d", "--entitlements", ":-", url.path]) ?? "Unable to inspect code signature."; DispatchQueue.main.async { output = result } } }
}
