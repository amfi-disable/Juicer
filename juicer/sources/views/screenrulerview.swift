import SwiftUI

struct screenrulerview: View {
    @State private var pixels = 320.0
    @State private var angle = 0.0
    var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "Screen Ruler & Protractor", subtitle: "Measure pixel distances and angles with interactive guides.", icon: "ruler", refreshing: false, action: {}) ; Slider(value: $pixels, in: 1...2000) { Text("Length") }; Text("Length: \(Int(pixels)) px (\(String(format: "%.2f", pixels / 96.0)) in)"); Slider(value: $angle, in: 0...360) { Text("Angle") }; Text("Angle: \(Int(angle))°"); RoundedRectangle(cornerRadius: 4).fill(.blue.opacity(0.25)).frame(width: pixels / 2, height: 8).rotationEffect(.degrees(angle)); Spacer() }.padding(24) }
}
