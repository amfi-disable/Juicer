import SwiftUI

struct JuicerFeatureHeader: View { let title: String; let subtitle: String; let icon: String; let refreshing: Bool; let action: () -> Void
    var body: some View { HStack { Image(systemName: icon).font(.title); VStack(alignment: .leading) { Text(title).font(.title2.bold()); Text(subtitle).foregroundStyle(.secondary) }; Spacer(); Button(action: action) { Image(systemName: refreshing ? "arrow.triangle.2.circlepath" : "arrow.clockwise") }.disabled(refreshing) } }
}
struct JuicerMetricTile: View { let title: String; let value: String; let detail: String; var color: Color = .accentColor; var body: some View { VStack(alignment: .leading) { Text(title).font(.caption).foregroundStyle(.secondary); Text(value).font(.title2.bold()).foregroundStyle(color); Text(detail).font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading).padding().background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10)) } }
struct JuicerFeatureList<Content: View>: View { let title: String; @ViewBuilder let content: Content; var body: some View { VStack(alignment: .leading, spacing: 10) { Text(title).font(.headline); content }.padding().background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10)) } }
