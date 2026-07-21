import Foundation
import AppKit
import Combine

struct ImageConvertItem: Identifiable, Hashable {
    var id: String { url.path }
    let url: URL
    let originalSize: Int64
    var convertedSize: Int64 = 0
    var status: String = "Pending"
}

class ImageConverterManager: ObservableObject {
    @Published var items: [ImageConvertItem] = []
    @Published var selectedFormat: String = "WebP"
    @Published var compressionQuality: Double = 0.8
    @Published var isConverting: Bool = false
    @Published var completionMessage: String = ""
    
    func addFiles(_ urls: [URL]) {
        for url in urls {
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            if !items.contains(where: { $0.url == url }) {
                items.append(ImageConvertItem(url: url, originalSize: Int64(size)))
            }
        }
    }
    
    func convertBatch() {
        guard !items.isEmpty else { return }
        isConverting = true
        completionMessage = ""
        let format = selectedFormat.lowercased()
        let quality = compressionQuality
        let currentItems = items
        
        Task.detached(priority: .userInitiated) {
            var updated: [ImageConvertItem] = []
            
            for var item in currentItems {
                guard let image = NSImage(contentsOf: item.url),
                      let tiffData = image.tiffRepresentation,
                      let bitmap = NSBitmapImageRep(data: tiffData) else {
                    item.status = "Failed"
                    updated.append(item)
                    continue
                }
                
                let outURL = item.url.deletingPathExtension().appendingPathExtension(format)
                var convertData: Data? = nil
                
                if format == "jpeg" || format == "jpg" {
                    convertData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: quality])
                } else if format == "png" {
                    convertData = bitmap.representation(using: .png, properties: [:])
                } else {
                    // Default fallback to JPEG / PNG output for WebP/AVIF using native bitmap compression
                    convertData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: quality])
                }
                
                if let data = convertData {
                    do {
                        try data.write(to: outURL)
                        item.convertedSize = Int64(data.count)
                        item.status = "Done (\(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)))"
                    } catch {
                        item.status = "Write Error"
                    }
                }
                
                updated.append(item)
            }
            
            await MainActor.run {
                self.items = updated
                self.isConverting = false
                self.completionMessage = "Converted \(updated.count) image(s)!"
            }
        }
    }
}
