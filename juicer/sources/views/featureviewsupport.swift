import SwiftUI

struct JuicerFeatureHeader: View { let title: String; let subtitle: String; let icon: String; let refreshing: Bool; let action: () -> Void
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 38, height: 38)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.title2.bold()).lineLimit(1)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)
            Spacer(minLength: 12)
            Button(action: action) {
                Image(systemName: refreshing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                    .symbolEffect(.pulse, isActive: refreshing)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Refresh \(title)")
            .disabled(refreshing)
        }
        .accessibilityElement(children: .combine)
        .padding(.bottom, 4)
    }
}

struct JuicerBackToHubButton: View {
    let action: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "house.fill")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.accentColor)
                    .frame(width: 24, height: 24)
                    .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
                
                Text("Back to Juicer Hub")
                    .font(.body.weight(.medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer(minLength: 4)
                
                Image(systemName: "chevron.left")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovering ? Color.accentColor.opacity(0.12) : Color(NSColor.controlBackgroundColor).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}
struct JuicerMetricTile: View { let title: String; let value: String; let detail: String; var color: Color = .accentColor; var body: some View { VStack(alignment: .leading, spacing: 5) { Text(title).font(.caption).foregroundStyle(.secondary); Text(value).font(.title2.bold()).foregroundStyle(color); Text(detail).font(.caption).foregroundStyle(.secondary).lineLimit(2) }.frame(maxWidth: .infinity, minHeight: 72, alignment: .leading).padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary)) } }
struct JuicerFeatureList<Content: View>: View { let title: String; @ViewBuilder let content: Content; var body: some View { VStack(alignment: .leading, spacing: 10) { Text(title).font(.headline); content }.frame(maxWidth: .infinity, alignment: .leading).padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary)) } }

struct JuicerUsageBar: View {
    let value: Double // 0 to 100
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.15))
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: geo.size.width * CGFloat(min(100, max(0, value)) / 100.0))
            }
        }
        .frame(height: 8)
    }
}

struct JuicerEmptyState: View {
    let title: String
    let detail: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// MARK: - Window Drag & Fit Support for All Windows
struct WindowDragAndFitModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(WindowAccessor())
    }
}

struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.isMovableByWindowBackground = true
            }
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

extension View {
    func allowWindowDragAndFit() -> some View {
        self.modifier(WindowDragAndFitModifier())
    }
}
