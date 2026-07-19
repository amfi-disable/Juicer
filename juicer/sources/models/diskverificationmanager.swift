import Foundation
import Combine

struct VerifiableDisk: Identifiable {
    let id: String
    let description: String
}

final class DiskVerificationManager: ObservableObject {
    @Published var disks: [VerifiableDisk] = []
    @Published var selectedID = ""
    @Published var output = ""
    @Published var working = false

    func scan() {
        let text = SystemMetricsSupport.run("/usr/sbin/diskutil", ["list"]) ?? "Unable to run diskutil."
        let found = text.components(separatedBy: .newlines).compactMap { line -> VerifiableDisk? in
            let tokens = line.split(whereSeparator: { $0 == " " || $0 == "\t" })
            guard let raw = tokens.first(where: { $0.hasPrefix("/dev/disk") || ($0.hasPrefix("disk") && $0.count > 4) }) else { return nil }
            let identifier = raw.replacingOccurrences(of: ":", with: "").replacingOccurrences(of: "/dev/", with: "")
            guard identifier.hasPrefix("disk") else { return nil }
            return VerifiableDisk(id: identifier, description: line.trimmingCharacters(in: .whitespaces))
        }
        disks = Array(Dictionary(grouping: found, by: \ .id).compactMap { $0.value.first }.sorted { $0.id < $1.id })
        if selectedID.isEmpty { selectedID = disks.first?.id ?? "" }
    }

    func verify() { run(["verifyVolume", selectedID], label: "Verification") }
    func repair() { run(["repairVolume", selectedID], label: "Repair") }

    private func run(_ arguments: [String], label: String) {
        guard !selectedID.isEmpty else { output = "Select a disk or volume first."; return }
        working = true
        DispatchQueue.global(qos: .userInitiated).async {
            let result = SystemMetricsSupport.run("/usr/sbin/diskutil", arguments) ?? "Unable to run diskutil."
            DispatchQueue.main.async { self.output = "\(label) \(self.selectedID)\n\(result)"; self.working = false }
        }
    }
}
