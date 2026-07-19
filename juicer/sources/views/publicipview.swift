import SwiftUI
import Foundation

struct publicipview: View { @State private var output = ""; var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "Public IP & Geoloc Lookup", subtitle: "Look up your public IP, provider, and approximate location.", icon: "globe", refreshing: false, action: lookup); Button("Lookup") { lookup() }.buttonStyle(.borderedProminent); Text(output.isEmpty ? "No lookup performed." : output).font(.system(.body, design: .monospaced)).textSelection(.enabled); Spacer() }.padding(24) }
    private func lookup() { guard let url = URL(string: "https://ipapi.co/json/") else { return }; URLSession.shared.dataTask(with: url) { data, _, error in let value = data.flatMap { try? JSONSerialization.jsonObject(with: $0) }; DispatchQueue.main.async { output = value.map { String(describing: $0) } ?? error?.localizedDescription ?? "Unable to look up public IP." } }.resume() }
}
