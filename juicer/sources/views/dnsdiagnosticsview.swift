import SwiftUI

struct dnsdiagnosticsview: View { @State private var host = "example.com"; @State private var server = "1.1.1.1"; @State private var output = ""; var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "DNS Resolver Diagnostics", subtitle: "Query a hostname against a selected DNS resolver and inspect timing.", icon: "network.badge.shield.half.filled", refreshing: false, action: resolve); HStack { TextField("Hostname", text: $host); TextField("DNS server", text: $server); Button("Resolve") { resolve() }.buttonStyle(.borderedProminent) }; ScrollView { Text(output).font(.system(.caption, design: .monospaced)).frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled) }; Spacer() }.padding(24) }
    private func resolve() { output = SystemMetricsSupport.run("/usr/bin/dig", ["@\(server)", host, "+stats", "+dnssec"]) ?? "dig is unavailable." }
}
