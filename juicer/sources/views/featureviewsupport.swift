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
                Text(title).font(.title2.bold())
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 12)
            Button(action: action) {
                Image(systemName: refreshing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                    .symbolEffect(.rotate, isActive: refreshing)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Refresh (title)")
            .disabled(refreshing)
        }
        .accessibilityElement(children: .combine)
        .padding(.bottom, 4)
    }
}
struct JuicerMetricTile: View { let title: String; let value: String; let detail: String; var color: Color = .accentColor; var body: some View { VStack(alignment: .leading, spacing: 5) { Text(title).font(.caption).foregroundStyle(.secondary); Text(value).font(.title2.bold()).foregroundStyle(color); Text(detail).font(.caption).foregroundStyle(.secondary).lineLimit(2) }.frame(maxWidth: .infinity, minHeight: 72, alignment: .leading).padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary)) } }
struct JuicerFeatureList<Content: View>: View { let title: String; @ViewBuilder let content: Content; var body: some View { VStack(alignment: .leading, spacing: 10) { Text(title).font(.headline); content }.frame(maxWidth: .infinity, alignment: .leading).padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary)) } }
