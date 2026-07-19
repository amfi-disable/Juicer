import SwiftUI

struct privacyscannerview: View {
    @State private var apps: [String] = []
    @State private var message = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Privacy Scanner", subtitle: "Inventory installed apps and review sensitive macOS permission categories.", icon: "hand.raised.shield", refreshing: false, action: scan)
            HStack { Text("Tracked categories: microphone, camera, screen recording, accessibility, full disk access").font(.caption).foregroundStyle(.secondary); Spacer(); Button("Scan") { scan() }.buttonStyle(.borderedProminent) }
            List(apps, id: \.self) { app in HStack { Image(systemName: "app"); Text(app); Spacer(); Text("Review in System Settings").font(.caption).foregroundStyle(.secondary) } }.listStyle(.inset)
            if !message.isEmpty { Text(message).font(.caption).foregroundStyle(.secondary) }
        }.padding(24).onAppear(perform: scan)
    }
    private func scan() { DispatchQueue.global().async { let output = SystemMetricsSupport.run("/usr/bin/mdfind", ["kMDItemContentType == 'com.apple.application-bundle'"]) ?? ""; let names = output.components(separatedBy: .newlines).filter { !$0.isEmpty }.map { URL(fileURLWithPath: $0).deletingPathExtension().lastPathComponent }.sorted(); DispatchQueue.main.async { apps = names; message = "Found \(names.count) installed application(s). Permission details are protected by macOS privacy controls." } } }
}
