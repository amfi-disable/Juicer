import SwiftUI

struct diskspacepredictorview: View { @State private var output = ""; var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "Disk Space Predictor", subtitle: "Inspect current disk capacity and a simple trend baseline.", icon: "chart.line.uptrend.xyaxis", refreshing: false, action: refresh); Button("Refresh Capacity") { refresh() }.buttonStyle(.borderedProminent); Text(output).font(.system(.body, design: .monospaced)).textSelection(.enabled); Text("Prediction improves when periodic samples are collected over time.").font(.caption).foregroundStyle(.secondary); Spacer() }.padding(24).onAppear(perform: refresh) }
    private func refresh() { output = SystemMetricsSupport.run("/bin/df", ["-h", "/"]) ?? "Unable to inspect disk capacity." }
}
