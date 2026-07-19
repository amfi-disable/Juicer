import SwiftUI
import Foundation

struct speedtestview: View { @State private var result = ""; @State private var running = false; var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "Speed Test Tool", subtitle: "Run a lightweight download latency and throughput test.", icon: "speedometer", refreshing: running, action: test); Button("Run Speed Test") { test() }.buttonStyle(.borderedProminent).disabled(running); Text(result.isEmpty ? "No test run." : result).font(.system(.body, design: .monospaced)); Spacer() }.padding(24) }
    private func test() { guard let url = URL(string: "https://speed.cloudflare.com/__down?bytes=1000000") else { return }; running = true; let start = Date(); URLSession.shared.dataTask(with: url) { data, _, error in let elapsed = Date().timeIntervalSince(start); DispatchQueue.main.async { if let data { let mbps = Double(data.count * 8) / elapsed / 1_000_000; result = String(format: "Downloaded %.2f MB in %.2f s\nEstimated throughput: %.2f Mbps", Double(data.count) / 1_000_000, elapsed, mbps) } else { result = error?.localizedDescription ?? "Speed test failed." }; running = false } }.resume() }
}
