import SwiftUI

struct landiscoveryview: View { @State private var service = "_http._tcp"; @State private var output = ""; var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "LAN Device Discovery", subtitle: "Browse Bonjour services advertised on the local network.", icon: "network", refreshing: false, action: discover); HStack { TextField("Bonjour service", text: $service); Button("Discover") { discover() }.buttonStyle(.borderedProminent) }; ScrollView { Text(output.isEmpty ? "Enter a service type such as _http._tcp or _ssh._tcp." : output).font(.system(.caption, design: .monospaced)).frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled) }; Spacer() }.padding(24) }
    private func discover() { DispatchQueue.global().async { let result = SystemMetricsSupport.run("/usr/bin/dns-sd", ["-B", service, "local"]) ?? "Unable to browse Bonjour services."; DispatchQueue.main.async { output = result } } }
}
