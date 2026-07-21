import Foundation
import Combine

struct AppLanguageBundle: Identifiable, Hashable {
    var id: String { path }
    let appName: String
    let path: String
    let languageCode: String
    let size: Int64
    var isSelected: Bool = true
}

class AppLanguageStripperManager: ObservableObject {
    @Published var foundBundles: [AppLanguageBundle] = []
    @Published var isScanning = false
    @Published var isStripping = false
    @Published var totalReclaimableSize: Int64 = 0
    
    private let systemLanguages: Set<String> = ["en", "Base", "English", "en_US", "en_GB", "en_AU", "zh_CN", "zh_TW", "zh-Hans", "zh-Hant"]
    
    func scanAppLanguages() {
        isScanning = true
        foundBundles = []
        totalReclaimableSize = 0
        
        Task.detached(priority: .userInitiated) {
            let appDirs = ["/Applications", "\(FileManager.default.homeDirectoryForCurrentUser.path)/Applications"]
            var results: [AppLanguageBundle] = []
            var totalBytes: Int64 = 0
            
            for appDir in appDirs {
                guard let apps = try? FileManager.default.contentsOfDirectory(atPath: appDir) else { continue }
                for app in apps where app.hasSuffix(".app") {
                    let resourcesPath = "\(appDir)/\(app)/Contents/Resources"
                    guard let contents = try? FileManager.default.contentsOfDirectory(atPath: resourcesPath) else { continue }
                    
                    for item in contents where item.hasSuffix(".lproj") {
                        let langCode = String(item.dropLast(6))
                        // Ignore system / essential language packs
                        if !self.systemLanguages.contains(langCode) {
                            let lprojPath = "\(resourcesPath)/\(item)"
                            let size = self.getFolderSize(path: lprojPath)
                            if size > 0 {
                                results.append(AppLanguageBundle(
                                    appName: String(app.dropLast(4)),
                                    path: lprojPath,
                                    languageCode: langCode,
                                    size: size,
                                    isSelected: true
                                ))
                                totalBytes += size
                            }
                        }
                    }
                }
            }
            
            let sorted = results.sorted(by: { $0.size > $1.size })
            await MainActor.run {
                self.foundBundles = sorted
                self.totalReclaimableSize = totalBytes
                self.isScanning = false
            }
        }
    }
    
    func stripSelectedLanguages(completion: @escaping (Bool) -> Void) {
        isStripping = true
        let selected = foundBundles.filter { $0.isSelected }
        
        Task.detached(priority: .userInitiated) {
            var successCount = 0
            for item in selected {
                do {
                    try FileManager.default.removeItem(atPath: item.path)
                    successCount += 1
                } catch {
                    AppLogger.shared.log("Failed to remove lproj at \(item.path): \(error.localizedDescription)")
                }
            }
            
            await MainActor.run {
                self.isStripping = false
                self.scanAppLanguages()
                completion(successCount > 0)
            }
        }
    }
    
    private func getFolderSize(path: String) -> Int64 {
        let url = URL(fileURLWithPath: path)
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var size: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize {
                size += Int64(fileSize)
            }
        }
        return size
    }
}
