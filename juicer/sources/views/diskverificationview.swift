import SwiftUI

struct diskverificationview: View {
    @StateObject private var manager = DiskVerificationManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            JuicerFeatureHeader(title: "Disk Verification & Repair", subtitle: "Verify or repair APFS and HFS volumes with diskutil.", icon: "checkmark.shield", refreshing: manager.working, action: manager.scan)
            HStack {
                Picker("Disk", selection: $manager.selectedID) { ForEach(manager.disks) { disk in Text(disk.description).tag(disk.id) } }.frame(maxWidth: 420)
                Button("Verify") { manager.verify() }
                Button("Repair…") { manager.repair() }.buttonStyle(.borderedProminent)
            }
            Text("Repair can unmount a volume and may require administrator approval.").font(.caption).foregroundStyle(.orange)
            ScrollView { Text(manager.output.isEmpty ? "Choose a disk or volume, then run a verification." : manager.output).font(.system(.caption, design: .monospaced)).frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled) }.padding(12).background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
            Spacer()
        }.padding(24).onAppear { manager.scan() }
    }
}
