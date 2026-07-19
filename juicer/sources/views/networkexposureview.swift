import SwiftUI

struct networkexposureview: View {
    @State private var rows: [String] = []
    @State private var message = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Network Exposure Monitor", subtitle: "Inspect listening TCP sockets and active network connections.", icon: "network.badge.shield.half.filled", refreshing: false, action: scan)
            HStack { Button("Scan Connections") { scan() }.buttonStyle(.borderedProminent); Spacer(); Text(message).font(.caption).foregroundStyle(.secondary) }
            List(rows, id: \.self) { Text($0).font(.system(.caption, design: .monospaced)).lineLimit(1).truncationMode(.middle) }.listStyle(.inset)
        }.padding(24).onAppear(perform: scan)
    }
    private func scan() { DispatchQueue.global().async { let text = SystemMetricsSupport.run("/usr/sbin/lsof", ["-nP", "-iTCP", "-sTCP:LISTEN"]) ?? "Unable to inspect sockets."; let lines = text.components(separatedBy: .newlines).filter { !$0.isEmpty }; DispatchQueue.main.async { rows = lines; message = "\(max(lines.count - 1, 0)) listening socket(s) found." } } }
}
