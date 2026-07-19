import SwiftUI
import AppKit

struct colorpickerview: View {
    @State private var colors: [NSColor] = []
    @State private var message = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Color Picker", subtitle: "Sample colors anywhere on screen and keep a copyable history.", icon: "eyedropper.halffull", refreshing: false, action: pick)
            HStack { Button("Pick Screen Color") { pick() }.buttonStyle(.borderedProminent); Spacer(); Button("Clear History") { colors.removeAll() } }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) { ForEach(Array(colors.enumerated()), id: \.offset) { _, color in Button { copy(color) } label: { HStack { RoundedRectangle(cornerRadius: 6).fill(Color(nsColor: color)).frame(width: 40, height: 30); Text(color.hex).font(.system(.caption, design: .monospaced)) } }.buttonStyle(.plain) } }
            if !message.isEmpty { Text(message).font(.caption).foregroundStyle(.secondary) }
            Spacer()
        }.padding(24)
    }
    private func pick() { NSColorSampler().show { color in guard let color else { return }; colors.insert(color.usingColorSpace(.sRGB) ?? color, at: 0); colors = Array(colors.prefix(20)) } }
    private func copy(_ color: NSColor) { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(color.hex, forType: .string); message = "Copied \(color.hex)." }
}

private extension NSColor { var hex: String { let color = usingColorSpace(.sRGB) ?? self; return String(format: "#%02X%02X%02X", Int(color.redComponent * 255), Int(color.greenComponent * 255), Int(color.blueComponent * 255)) } }
