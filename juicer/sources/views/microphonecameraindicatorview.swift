import SwiftUI
import AVFoundation

struct microphonecameraindicatorview: View {
    @State private var microphone = "unknown"
    @State private var camera = "unknown"
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Microphone & Camera Indicator", subtitle: "Show current capture authorization and the macOS privacy indicator guidance.", icon: "mic.and.signal.meter", refreshing: false, action: refresh)
            HStack { Label("Microphone: \(microphone)", systemImage: "mic"); Spacer(); Label("Camera: \(camera)", systemImage: "camera") }
            Text("When an app actively uses either sensor, macOS displays its orange or green indicator. Juicer does not activate either device while checking status.").font(.caption).foregroundStyle(.secondary)
            Spacer()
        }.padding(24).onAppear(perform: refresh)
    }
    private func refresh() { microphone = AVCaptureDevice.authorizationStatus(for: .audio).description; camera = AVCaptureDevice.authorizationStatus(for: .video).description }
}

private extension AVAuthorizationStatus { var description: String { switch self { case .authorized: "authorized"; case .denied: "denied"; case .restricted: "restricted"; case .notDetermined: "not requested" @unknown default: "unknown" } } }
