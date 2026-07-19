import SwiftUI

struct softwareinventoryview: View { @State private var apps: [String] = []; var body: some View { VStack(alignment: .leading, spacing: 16) { JuicerFeatureHeader(title: "License & Software Inventory", subtitle: "List installed application bundles and their locations.", icon: "shippingbox", refreshing: false, action: scan); Button("Scan Installed Apps") { scan() }.buttonStyle(.borderedProminent); List(apps, id: \.self) { Text($0).lineLimit(1).truncationMode(.middle) }.listStyle(.inset) }.padding(24).onAppear(perform: scan) }
    private func scan() { let output = SystemMetricsSupport.run("/usr/bin/mdfind", ["kMDItemContentType == 'com.apple.application-bundle'"]) ?? ""; apps = output.components(separatedBy: .newlines).filter { !$0.isEmpty }.sorted() }
}
