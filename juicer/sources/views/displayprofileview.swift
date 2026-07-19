import SwiftUI

struct displayprofileview: View { @State private var output = ""; var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "Display Profile Manager", subtitle: "Inspect connected displays and their ICC profile details.", icon: "display.2", refreshing: false, action: refresh); Button("Refresh Displays") { refresh() }.buttonStyle(.borderedProminent); ScrollView { Text(output).font(.system(.caption, design: .monospaced)).frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled) }; Spacer() }.padding(24).onAppear(perform: refresh) }
    private func refresh() { output = SystemMetricsSupport.run("/usr/sbin/system_profiler", ["SPDisplaysDataType"]) ?? "Unable to inspect displays." }
}
