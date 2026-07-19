import SwiftUI

struct printerqueueview: View {
    @State private var jobs: [String] = []
    @State private var message = ""
    var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "Printer Queue Manager", subtitle: "Inspect CUPS queues and cancel selected print jobs.", icon: "printer", refreshing: false, action: refresh); HStack { Button("Refresh") { refresh() }.buttonStyle(.borderedProminent); Button("Cancel Selected") { if let job = jobs.first { cancel(job) } }; Spacer(); Text(message).font(.caption).foregroundStyle(.secondary) }; List(jobs, id: \.self) { Text($0).font(.system(.caption, design: .monospaced)) }.listStyle(.inset) }.padding(24).onAppear(perform: refresh) }
    private func refresh() { let output = SystemMetricsSupport.run("/usr/bin/lpstat", ["-o"]) ?? "Unable to query printer queues."; jobs = output.components(separatedBy: .newlines).filter { !$0.isEmpty }; message = "\(jobs.count) queued job(s)." }
    private func cancel(_ line: String) { let job = String(line.split(separator: " ").first ?? ""); _ = SystemMetricsSupport.run("/usr/bin/cancel", [job]); refresh() }
}
