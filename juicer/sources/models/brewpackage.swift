import Foundation

struct BrewPackage: Identifiable, Hashable, Codable {
    var id: String { name }
    let name: String
    let version: String
    let type: PackageType // "Formula" or "Cask"
    var isOutdated: Bool
    var latestVersion: String?
    
    enum PackageType: String, Codable {
        case formula = "Formula"
        case cask = "Cask"
    }
}
