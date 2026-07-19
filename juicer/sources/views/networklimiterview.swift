import SwiftUI

struct networklimiterview: View { @State private var output = ""; var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "Network Speed Limiter", subtitle: "Inspect packet-filter rules used for bandwidth controls.", icon: "gauge.with.dots.needle.33percent", refreshing: false, action: refresh); Button("Inspect pf Rules") { refresh() }.buttonStyle(.borderedProminent); Text("Changing pf bandwidth rules requires administrator approval and a carefully scoped ruleset.").font(.caption).foregroundStyle(.orange); ScrollView { Text(output).font(.system(.caption, design: .monospaced)).frame(maxWidth: .infinity, alignment: .leading) }; Spacer() }.padding(24).onAppear(perform: refresh) }
    private func refresh() { output = SystemMetricsSupport.run("/sbin/pfctl", ["-sr"]) ?? "pfctl unavailable or permission denied." }
}
