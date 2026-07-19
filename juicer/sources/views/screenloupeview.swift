import SwiftUI

struct screenloupeview: View {
    @State private var zoom = 4.0
    @State private var color = Color.accentColor
    var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "Pixel-Perfect Screen Loupe", subtitle: "Configure a magnification lens and sampling guide for screen inspection.", icon: "magnifyingglass", refreshing: false, action: {}) ; Slider(value: $zoom, in: 1...20) { Text("Zoom") }; Text("Magnification: \(String(format: "%.1f×", zoom))"); ZStack { Circle().fill(color.gradient).frame(width: 180, height: 180); Circle().stroke(.white, lineWidth: 2).frame(width: 180, height: 180); Rectangle().fill(.white.opacity(0.7)).frame(width: 1, height: 180); Rectangle().fill(.white.opacity(0.7)).frame(width: 180, height: 1) }; ColorPicker("Sample color", selection: $color); Spacer() }.padding(24) }
}
