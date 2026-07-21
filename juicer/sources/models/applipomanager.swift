import Foundation
import AppKit

struct LipoAppItem: Identifiable, Hashable {
    let id: UUID = UUID()
    let appName: String
    let bundleIdentifier: String
    let path: URL
    let icon: NSImage
    let totalSize: Int64
    let architectures: [String]
    let estimatedSavings: Int64
    var isThinned: Bool
}

class AppLipoManager: ObservableObject {
    @Published var universalApps: [LipoAppItem] = []
    @Published var isScanning = false
    @Published var isThinning = false
    
    private let fileManager = FileManager.default
    
    // Mach-O constants
    private let FAT_MAGIC: UInt32 = 0xcafebabe
    private let FAT_CIGAM: UInt32 = 0xbebafeca
    private let CPU_TYPE_ARM64: UInt32 = 0x100000c
    private let CPU_TYPE_X86_64: UInt32 = 0x01000007
    
    struct FatHeader {
        let magic: UInt32
        let numArchitectures: UInt32
    }
    
    struct FatArch {
        let cpuType: UInt32
        let cpuSubtype: UInt32
        let offset: UInt32
        let size: UInt32
        let align: UInt32
    }
    
    func scanForUniversalApps() {
        self.isScanning = true
        self.universalApps = []
        AppLogger.shared.log("Scanning applications directory for Universal binaries...")
        
        Task.detached(priority: .userInitiated) {
            let scanPaths = ["/Applications", "/System/Applications"]
            var discovered: [LipoAppItem] = []
            
            for basePath in scanPaths {
                let baseFolder = URL(fileURLWithPath: basePath)
                guard let enumerator = self.fileManager.enumerator(
                    at: baseFolder,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]
                ) else { continue }
                
                for case let fileURL as URL in enumerator {
                    if fileURL.pathExtension == "app" {
                        self.processAppBundle(fileURL, discovered: &discovered)
                    }
                }
            }
            
            let sorted = discovered.sorted(by: { $0.estimatedSavings > $1.estimatedSavings })
            
            await MainActor.run {
                self.universalApps = sorted
                self.isScanning = false
                AppLogger.shared.log("Scan complete. Discovered \(sorted.count) universal applications.")
            }
        }
    }
    
    private func processAppBundle(_ bundleURL: URL, discovered: inout [LipoAppItem]) {
        let info = AppInfo(path: bundleURL)
        guard !info.appName.isEmpty else { return }
        
        // Find main executable
        let infoPlistURL = bundleURL.appendingPathComponent("Contents/Info.plist")
        guard let plist = NSDictionary(contentsOf: infoPlistURL),
              let execName = plist["CFBundleExecutable"] as? String,
              !execName.contains("/"),
              !execName.contains("..") else { return }
        
        let macosDir = bundleURL.appendingPathComponent("Contents/MacOS").standardizedFileURL
        let execURL = bundleURL.appendingPathComponent("Contents/MacOS").appendingPathComponent(execName).standardizedFileURL
        guard execURL.path.hasPrefix(macosDir.path),
              fileManager.fileExists(atPath: execURL.path) else { return }
        
        // Parse Mach-O header
        guard let fileHandle = try? FileHandle(forReadingFrom: execURL) else { return }
        defer { try? fileHandle.close() }
        
        guard let headerData = try? fileHandle.read(upToCount: 8), headerData.count == 8 else { return }
        
        let magic = headerData.withUnsafeBytes { $0.load(fromByteOffset: 0, as: UInt32.self).bigEndian }
        
        if magic == FAT_MAGIC || magic == FAT_CIGAM {
            // It is a FAT / Universal binary!
            let numArchs = headerData.withUnsafeBytes { $0.load(fromByteOffset: 4, as: UInt32.self).bigEndian }
            
            var archs: [FatArch] = []
            for _ in 0..<numArchs {
                guard let archData = try? fileHandle.read(upToCount: 20), archData.count == 20 else { return }
                
                let arch = archData.withUnsafeBytes { ptr in
                    FatArch(
                        cpuType: ptr.load(fromByteOffset: 0, as: UInt32.self).bigEndian,
                        cpuSubtype: ptr.load(fromByteOffset: 4, as: UInt32.self).bigEndian,
                        offset: ptr.load(fromByteOffset: 8, as: UInt32.self).bigEndian,
                        size: ptr.load(fromByteOffset: 12, as: UInt32.self).bigEndian,
                        align: ptr.load(fromByteOffset: 16, as: UInt32.self).bigEndian
                    )
                }
                archs.append(arch)
            }
            
            // Build arch string representations and calculate sizes
            var architectures: [String] = []
            var armSize: Int64 = 0
            var intelSize: Int64 = 0
            
            for arch in archs {
                if arch.cpuType == CPU_TYPE_ARM64 {
                    architectures.append("Apple Silicon (arm64)")
                    armSize = Int64(arch.size)
                } else if arch.cpuType == CPU_TYPE_X86_64 {
                    architectures.append("Intel (x86_64)")
                    intelSize = Int64(arch.size)
                }
            }
            
            // If it has multiple slices, calculate potential savings
            if architectures.count > 1 {
                let appSize = getPathSize(bundleURL)
                
                // Native arch determination
                var estimatedSavings: Int64 = 0
                #if arch(arm64)
                estimatedSavings = intelSize // Thinning on Apple Silicon saves the Intel binary size
                #else
                estimatedSavings = armSize   // Thinning on Intel saves the ARM binary size
                #endif
                
                discovered.append(LipoAppItem(
                    appName: info.appName,
                    bundleIdentifier: info.bundleIdentifier,
                    path: bundleURL,
                    icon: info.icon,
                    totalSize: appSize,
                    architectures: architectures,
                    estimatedSavings: estimatedSavings,
                    isThinned: false
                ))
            }
        }
    }
    
    func thinApplication(_ app: LipoAppItem, completion: @escaping (Bool) -> Void) {
        self.isThinning = true
        AppLogger.shared.log("Thinning application binary: \(app.appName)...")
        
        Task.detached(priority: .userInitiated) {
            let infoPlistURL = app.path.appendingPathComponent("Contents/Info.plist")
            guard let plist = NSDictionary(contentsOf: infoPlistURL),
                  let execName = plist["CFBundleExecutable"] as? String,
                  !execName.contains("/"),
                  !execName.contains("..") else {
                await MainActor.run { self.isThinning = false }
                completion(false)
                return
            }
            
            let macosDir = app.path.appendingPathComponent("Contents/MacOS").standardizedFileURL
            let execURL = app.path.appendingPathComponent("Contents/MacOS").appendingPathComponent(execName).standardizedFileURL
            guard execURL.path.hasPrefix(macosDir.path) else {
                await MainActor.run { self.isThinning = false }
                completion(false)
                return
            }
            guard let fileHandle = try? FileHandle(forReadingFrom: execURL) else {
                await MainActor.run { self.isThinning = false }
                completion(false)
                return
            }
            
            // Read headers to find native offset
            guard let headerData = try? fileHandle.read(upToCount: 8), headerData.count == 8 else {
                try? fileHandle.close()
                await MainActor.run { self.isThinning = false }
                completion(false)
                return
            }
            
            let numArchs = headerData.withUnsafeBytes { $0.load(fromByteOffset: 4, as: UInt32.self).bigEndian }
            
            var targetArch: FatArch?
            
            for _ in 0..<numArchs {
                guard let archData = try? fileHandle.read(upToCount: 20), archData.count == 20 else { break }
                
                let arch = archData.withUnsafeBytes { ptr in
                    FatArch(
                        cpuType: ptr.load(fromByteOffset: 0, as: UInt32.self).bigEndian,
                        cpuSubtype: ptr.load(fromByteOffset: 4, as: UInt32.self).bigEndian,
                        offset: ptr.load(fromByteOffset: 8, as: UInt32.self).bigEndian,
                        size: ptr.load(fromByteOffset: 12, as: UInt32.self).bigEndian,
                        align: ptr.load(fromByteOffset: 16, as: UInt32.self).bigEndian
                    )
                }
                
                #if arch(arm64)
                if arch.cpuType == self.CPU_TYPE_ARM64 {
                    targetArch = arch
                    break
                }
                #else
                if arch.cpuType == self.CPU_TYPE_X86_64 {
                    targetArch = arch
                    break
                }
                #endif
            }
            
            guard let target = targetArch else {
                try? fileHandle.close()
                await MainActor.run { self.isThinning = false }
                completion(false)
                return
            }
            
            // Extract the slice bytes
            try? fileHandle.seek(toOffset: UInt64(target.offset))
            guard let sliceData = try? fileHandle.read(upToCount: Int(target.size)) else {
                try? fileHandle.close()
                await MainActor.run { self.isThinning = false }
                completion(false)
                return
            }
            try? fileHandle.close()
            
            // Overwrite binary with native slice
            do {
                try sliceData.write(to: execURL)
                AppLogger.shared.log("Successfully thinned binary for \(app.appName). Saved \(self.formatBytes(app.estimatedSavings))!")
                
                // Update local status
                await MainActor.run {
                    if let index = self.universalApps.firstIndex(where: { $0.id == app.id }) {
                        self.universalApps[index].isThinned = true
                    }
                    self.isThinning = false
                    // Refresh app details
                    self.scanForUniversalApps()
                }
                completion(true)
            } catch {
                AppLogger.shared.log("Failed to write thinned slice: \(error.localizedDescription)")
                await MainActor.run { self.isThinning = false }
                completion(false)
            }
        }
    }
    
    private func getPathSize(_ url: URL) -> Int64 {
        var size: Int64 = 0
        let keys: [URLResourceKey] = [.fileSizeKey, .isDirectoryKey]
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: []
        ) else { return 0 }
        
        for case let fileURL as URL in enumerator {
            if let resourceValues = try? fileURL.resourceValues(forKeys: Set(keys)) {
                let isDirectory = resourceValues.isDirectory ?? false
                if !isDirectory {
                    size += Int64(resourceValues.fileSize ?? 0)
                }
            }
        }
        
        return size
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
