import Foundation
import Combine

enum DownloadCategory: String, CaseIterable {
    case images = "Images", video = "Video", audio = "Audio", documents = "Documents", archives = "Archives", applications = "Applications", other = "Other"
    var extensions: Set<String> {
        switch self {
        case .images: return ["jpg", "jpeg", "png", "gif", "heic", "webp", "tiff", "svg"]
        case .video: return ["mp4", "mov", "mkv", "avi", "m4v", "webm"]
        case .audio: return ["mp3", "m4a", "wav", "flac", "aac", "ogg"]
        case .documents: return ["pdf", "doc", "docx", "txt", "rtf", "md", "xls", "xlsx", "ppt", "pptx", "csv"]
        case .archives: return ["zip", "tar", "gz", "bz2", "xz", "7z", "rar"]
        case .applications: return ["dmg", "pkg", "app"]
        case .other: return []
        }
    }
}

struct DownloadItem: Identifiable {
    let id = UUID()
    let url: URL
    let category: DownloadCategory
    let month: String
    var selected = true
}

final class DownloadOrganizer: ObservableObject {
    @Published var items: [DownloadItem] = []
    @Published var isScanning = false
    @Published var isOrganizing = false
    @Published var message = ""
    let downloadsURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")

    func scan() {
        isScanning = true
        DispatchQueue.global(qos: .userInitiated).async {
            let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM"
            let urls = (try? FileManager.default.contentsOfDirectory(at: self.downloadsURL, includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey], options: [.skipsHiddenFiles])) ?? []
            let items = urls.compactMap { url -> DownloadItem? in
                guard (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) != true else { return nil }
                let category = DownloadCategory.allCases.first { $0 != .other && $0.extensions.contains(url.pathExtension.lowercased()) } ?? .other
                let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? nil
                return DownloadItem(url: url, category: category, month: date.map(formatter.string(from:)) ?? "unknown")
            }
            DispatchQueue.main.async { self.items = items.sorted { $0.url.lastPathComponent < $1.url.lastPathComponent }; self.message = "Classified \(items.count) Downloads items."; self.isScanning = false }
        }
    }

    func organize() {
        isOrganizing = true
        let selected = items.filter(\.selected)
        for item in selected {
            let destination = downloadsURL.appendingPathComponent(item.category.rawValue).appendingPathComponent(item.month)
            try? FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
            var target = destination.appendingPathComponent(item.url.lastPathComponent)
            if FileManager.default.fileExists(atPath: target.path) { target = destination.appendingPathComponent("\(UUID().uuidString.prefix(8))_\(item.url.lastPathComponent)") }
            try? FileManager.default.moveItem(at: item.url, to: target)
        }
        isOrganizing = false
        message = "Organized \(selected.count) selected items by type and month."
        scan()
    }
}
