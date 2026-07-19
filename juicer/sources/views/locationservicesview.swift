import SwiftUI
import CoreLocation

struct locationservicesview: View {
    @State private var status = "Unknown"
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Location Services Auditor", subtitle: "Review this app's location authorization and open macOS privacy settings.", icon: "location.fill", refreshing: false, action: refresh)
            HStack { Text("Juicer authorization: \(status)"); Spacer(); Button("Refresh") { refresh() } }
            Text("macOS keeps per-app location history private. Detailed grants and recent use are available in System Settings → Privacy & Security → Location Services.").font(.caption).foregroundStyle(.secondary)
            Spacer()
        }.padding(24).onAppear(perform: refresh)
    }
    private func refresh() { status = String(describing: CLLocationManager.authorizationStatus()) }
}
