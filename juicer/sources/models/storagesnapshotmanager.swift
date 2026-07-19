import Foundation
import Combine

struct APFSStorageSnapshot: Identifiable {
    let id: String
    let detail: String
}

final class StorageSnapshotManager: ObservableObject {
    @Published var volume = "/"
    @Published var snapshots: [APFSStorageSnapshot] = []
    @Published var selectedID = ""
    @Published var output = ""
    @Published var working = false

    func refresh() {
        working = true
        let selectedVolume = volume
        DispatchQueue.global(qos: .userInitiated).async {
            let result = SystemMetricsSupport.run("/usr/sbin/diskutil", ["apfs", "listSnapshots", selectedVolume]) ?? "Unable to list snapshots."
            let parsed = result.components(separatedBy: .newlines).compactMap { line -> APFSStorageSnapshot? in
                guard let range = line.range(of: "Snapshot UUID:") else { return nil }
                let uuid = line[range.upperBound...].trimmingCharacters(in: .whitespaces)
                return uuid.isEmpty ? nil : APFSStorageSnapshot(id: uuid, detail: line.trimmingCharacters(in: .whitespaces))
            }
            DispatchQueue.main.async { self.snapshots = parsed; self.output = result; self.working = false; if !parsed.contains(where: { $0.id == self.selectedID }) { self.selectedID = parsed.first?.id ?? "" } }
        }
    }

    func create() { run(["apfs", "snapshot", volume], message: "Snapshot created.") }
    func delete() { guard !selectedID.isEmpty else { output = "Select a snapshot first."; return }; run(["apfs", "deleteSnapshot", volume, "-uuid", selectedID], message: "Snapshot deleted.") }
    func rollback() { guard !selectedID.isEmpty else { output = "Select a snapshot first."; return }; run(["apfs", "revertToSnapshot", volume, "-uuid", selectedID], message: "Rollback requested.") }

    private func run(_ arguments: [String], message: String) {
        working = true
        DispatchQueue.global(qos: .userInitiated).async {
            let result = SystemMetricsSupport.run("/usr/sbin/diskutil", arguments) ?? "Unable to run diskutil."
            DispatchQueue.main.async { self.output = result.isEmpty ? message : result; self.working = false; self.refresh() }
        }
    }
}
