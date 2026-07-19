import SwiftUI

struct systemservicesview: View { @State private var output = ""; var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "System Service Status", subtitle: "Inspect launchd service state and process identifiers.", icon: "gearshape.2", refreshing: false, action: refresh); Button("Refresh Services") { refresh() }.buttonStyle(.borderedProminent); ScrollView { Text(output).font(.system(.caption, design: .monospaced)).frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled) }; Spacer() }.padding(24).onAppear(perform: refresh) }
    private func refresh() { output = SystemMetricsSupport.run("/bin/launchctl", ["list"]) ?? "Unable to query launchctl." }
}
