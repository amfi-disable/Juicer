import SwiftUI
import UniformTypeIdentifiers

struct airdropquicksendview: View {
    @StateObject private var manager = AirDropQuickSendManager()

    var body: some View {
        VStack(spacing: 18) {
            JuicerFeatureHeader(title: "AirDrop Quick-Send", subtitle: "Drag files onto this tool or use its menu-bar item to send nearby.", icon: "airplayaudio", refreshing: false, action: manager.clear)
            VStack(spacing: 10) {
                Image(systemName: manager.isTargeted ? "arrow.down.circle.fill" : "airplayaudio")
                    .font(.system(size: 44))
                    .foregroundStyle(manager.isTargeted ? Color.accentColor : Color.secondary)
                Text("Drop files here")
                    .font(.headline)
                Text(manager.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 170)
            .background(Color.accentColor.opacity(manager.isTargeted ? 0.18 : 0.07), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.accentColor.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [6])))
            .onDrop(of: [UTType.fileURL], isTargeted: $manager.isTargeted) { providers in manager.add(providers: providers) }
            if !manager.files.isEmpty {
                List(manager.files, id: \.self) { file in Label(file.lastPathComponent, systemImage: "doc") }
                    .listStyle(.inset)
            }
            HStack {
                Button("Clear") { manager.clear() }.disabled(manager.files.isEmpty)
                Spacer()
                Button("Send with AirDrop") { manager.send() }.buttonStyle(.borderedProminent).disabled(!manager.canSend)
            }
        }
        .padding(24)
    }
}
