import SwiftUI
import Foundation

struct blocklistupdaterview: View { @State private var url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"; @State private var message = ""; var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "Ad-block List Updater", subtitle: "Download and inspect a hosts-based malware or ad-block list.", icon: "shield.checkered", refreshing: false, action: update); TextField("Blocklist URL", text: $url); Button("Download Update") { update() }.buttonStyle(.borderedProminent); Text(message).font(.caption).foregroundStyle(.secondary); Text("Review downloaded content before merging it into /etc/hosts.").font(.caption).foregroundStyle(.orange); Spacer() }.padding(24) }
    private func update() { guard let address = URL(string: url) else { message = "Invalid URL."; return }; URLSession.shared.dataTask(with: address) { data, _, error in DispatchQueue.main.async { if let data { let lines = String(data: data, encoding: .utf8)?.split(separator: "\n").count ?? 0; message = "Downloaded \(lines) lines (\(data.count) bytes)." } else { message = error?.localizedDescription ?? "Download failed." } } }.resume() }
}
