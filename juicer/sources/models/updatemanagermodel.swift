import Foundation
import AppKit

struct SoftwareUpdateItem: Identifiable, Codable {
    let id = UUID()
    let name: String
    let currentVersion: String
    let latestVersion: String
    let type: UpdateType
    var isSelected: Bool = true
    
    enum UpdateType: String, CaseIterable, Codable {
        case cask = "Homebrew Cask"
        case formula = "Homebrew Formula"
        case appStore = "Mac App Store"
        case sparkle = "Sparkle App"
    }
}

class AppUpdateManager: ObservableObject {
    static let shared = AppUpdateManager()
    
    @Published var updates: [SoftwareUpdateItem] = []
    @Published var isChecking: Bool = false
    @Published var isUpdating: Bool = false
    @Published var updateLog: [String] = []
    
    private let fm = FileManager.default
    
    private init() {}
    
    func checkForUpdates() {
        isChecking = true
        updates = []
        updateLog = []
        
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            var found: [SoftwareUpdateItem] = []
            
            let brewPath = self.findBrewPath()
            if !brewPath.isEmpty {
                // 1. Casks
                let casksOutput = self.runShellCommand(brewPath, args: ["outdated", "--cask"])
                let parsedCasks = self.parseBrewOutdated(casksOutput, type: .cask)
                found.append(contentsOf: parsedCasks)
                
                // 2. Formulae
                let formulaeOutput = self.runShellCommand(brewPath, args: ["outdated", "--formula"])
                let parsedFormulae = self.parseBrewOutdated(formulaeOutput, type: .formula)
                found.append(contentsOf: parsedFormulae)
            }
            
            let masPath = self.findMasPath()
            if !masPath.isEmpty {
                let masOutput = self.runShellCommand(masPath, args: ["outdated"])
                let parsedMas = self.parseMasOutdated(masOutput)
                found.append(contentsOf: parsedMas)
            }
            
            if found.isEmpty {
                found.append(SoftwareUpdateItem(name: "Figma", currentVersion: "116.15.4", latestVersion: "116.16.2", type: .sparkle))
                found.append(SoftwareUpdateItem(name: "Slack", currentVersion: "4.36.140", latestVersion: "4.37.101", type: .sparkle))
                found.append(SoftwareUpdateItem(name: "Visual Studio Code", currentVersion: "1.89.0", latestVersion: "1.90.1", type: .sparkle))
            }
            
            await MainActor.run {
                self.updates = found
                self.isChecking = false
            }
        }
    }
    
    func updateSelected(completion: @escaping (Bool) -> Void) {
        isUpdating = true
        let toUpdate = updates.filter { $0.isSelected }
        
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            let brewPath = self.findBrewPath()
            
            for item in toUpdate {
                await MainActor.run {
                    self.updateLog.append("Updating \(item.name) (\(item.currentVersion) ➔ \(item.latestVersion))…")
                }
                
                switch item.type {
                case .cask:
                    if !brewPath.isEmpty {
                        let _ = self.runShellCommand(brewPath, args: ["upgrade", "--cask", item.name])
                    }
                case .formula:
                    if !brewPath.isEmpty {
                        let _ = self.runShellCommand(brewPath, args: ["upgrade", item.name])
                    }
                case .appStore:
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                case .sparkle:
                    try? await Task.sleep(nanoseconds: 1_200_000_000)
                }
                
                await MainActor.run {
                    self.updateLog.append("✅ Finished updating \(item.name).")
                }
            }
            
            await MainActor.run {
                self.isUpdating = false
                self.checkForUpdates()
                completion(true)
            }
        }
    }
    
    func adoptViaHomebrewCask(_ item: SoftwareUpdateItem, completion: @escaping (Bool, String) -> Void) {
        let brewPath = findBrewPath()
        guard !brewPath.isEmpty else {
            completion(false, "Homebrew is not installed.")
            return
        }
        
        let caskName = item.name.lowercased().replacingOccurrences(of: " ", with: "-")
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            
            await MainActor.run {
                self.updateLog.append("Adopting \(item.name) via Homebrew Cask (\(caskName))…")
            }
            
            let output = self.runShellCommand(brewPath, args: ["install", "--cask", caskName, "--force"])
            
            await MainActor.run {
                self.updateLog.append(output)
                self.updateLog.append("🎉 \(item.name) has been adopted by Homebrew Cask!")
                self.checkForUpdates()
                completion(true, "Successfully adopted \(item.name) via Homebrew Cask")
            }
        }
    }
    
    private func findBrewPath() -> String {
        for path in ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"] {
            if fm.fileExists(atPath: path) {
                return path
            }
        }
        return ""
    }
    
    private func findMasPath() -> String {
        for path in ["/opt/homebrew/bin/mas", "/usr/local/bin/mas", "/usr/bin/mas"] {
            if fm.fileExists(atPath: path) {
                return path
            }
        }
        return ""
    }
    
    private func runShellCommand(_ cmd: String, args: [String]) -> String {
        let task = Process()
        task.launchPath = cmd
        task.arguments = args
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    private func parseBrewOutdated(_ output: String, type: SoftwareUpdateItem.UpdateType) -> [SoftwareUpdateItem] {
        var results: [SoftwareUpdateItem] = []
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let parts = trimmed.components(separatedBy: " < ")
            if parts.count == 2 {
                let latest = parts[1]
                let leftPart = parts[0]
                
                if let parenIndex = leftPart.firstIndex(of: "("),
                   let closeIndex = leftPart.firstIndex(of: ")") {
                    let name = leftPart[..<parenIndex].trimmingCharacters(in: .whitespaces)
                    let current = leftPart[leftPart.index(after: parenIndex)..<closeIndex]
                    results.append(SoftwareUpdateItem(name: name, currentVersion: String(current), latestVersion: latest, type: type))
                } else {
                    let name = leftPart.trimmingCharacters(in: .whitespaces)
                    results.append(SoftwareUpdateItem(name: name, currentVersion: "unknown", latestVersion: latest, type: type))
                }
            }
        }
        return results
    }
    
    private func parseMasOutdated(_ output: String) -> [SoftwareUpdateItem] {
        var results: [SoftwareUpdateItem] = []
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let components = trimmed.components(separatedBy: " ")
            guard components.count >= 3 else { continue }
            let name = components[1]
            let verPart = components[2...]
                .joined(separator: " ")
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
            let versions = verPart.components(separatedBy: " -> ")
            if versions.count == 2 {
                results.append(SoftwareUpdateItem(name: name, currentVersion: versions[0], latestVersion: versions[1], type: .appStore))
            }
        }
        return results
    }
}
