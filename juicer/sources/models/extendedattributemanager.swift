import Foundation
import Combine

struct ExtendedAttribute: Identifiable {
    let id = UUID()
    let name: String
    var value: String
}

final class ExtendedAttributeManager: ObservableObject {
    @Published var selectedURL: URL?
    @Published var attributes: [ExtendedAttribute] = []
    @Published var attributeName = ""
    @Published var attributeValue = ""
    @Published var message = "Choose a file or folder to inspect."

    func select(_ url: URL) { selectedURL = url; refresh() }

    func refresh() {
        guard let selectedURL else { return }
        let output = SystemMetricsSupport.run("/usr/bin/xattr", ["-l", selectedURL.path]) ?? ""
        attributes = output.split(separator: "\n").map { line in let parts = line.split(separator: ":", maxSplits: 1); return ExtendedAttribute(name: String(parts.first ?? ""), value: parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespaces) : "") }
        message = "Found \(attributes.count) extended attribute(s)."
    }

    func write() {
        guard let selectedURL, !attributeName.isEmpty else { return }
        _ = SystemMetricsSupport.run("/usr/bin/xattr", ["-w", attributeName, attributeValue, selectedURL.path]); refresh()
    }

    func delete(_ attribute: ExtendedAttribute) {
        guard let selectedURL else { return }
        _ = SystemMetricsSupport.run("/usr/bin/xattr", ["-d", attribute.name, selectedURL.path]); refresh()
    }
}
