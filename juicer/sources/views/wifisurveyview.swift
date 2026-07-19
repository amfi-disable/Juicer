import SwiftUI

struct wifisurveyview: View { @State private var output = ""; var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "Wi-Fi Survey Tool", subtitle: "Inspect nearby-network and channel information reported by macOS.", icon: "wifi", refreshing: false, action: scan); Button("Scan Wi-Fi") { scan() }.buttonStyle(.borderedProminent); ScrollView { Text(output.isEmpty ? "Run a scan to inspect Wi-Fi details." : output).font(.system(.caption, design: .monospaced)).frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled) }; Spacer() }.padding(24).onAppear(perform: scan) }
    private func scan() { DispatchQueue.global().async { let result = SystemMetricsSupport.run("/usr/sbin/system_profiler", ["SPAirPortDataType"]) ?? "Unable to inspect Wi-Fi."; DispatchQueue.main.async { output = result } } }
}
