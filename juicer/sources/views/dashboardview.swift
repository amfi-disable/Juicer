import SwiftUI

struct dashboardview: View {
    @State private var totalDiskSpace: String = "Loading..."
    @State private var freeDiskSpace: String = "Loading..."
    @State private var usedDiskSpacePercentage: Double = 0.0
    @State private var macOSVersion: String = ProcessInfo.processInfo.operatingSystemVersionString
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // Welcome Banner
                VStack(alignment: .leading, spacing: 8) {
                    Text("juicer")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("The Ultimate Open-Source macOS Developer Utility")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                Divider()
                
                // System Summary Card
                VStack(alignment: .leading, spacing: 20) {
                    Text("System Storage")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 30) {
                        // Circular Progress
                        ZStack {
                            Circle()
                                .stroke(Color.secondary.opacity(0.15), lineWidth: 16)
                                .frame(width: 120, height: 120)
                            
                            Circle()
                                .trim(from: 0.0, to: CGFloat(usedDiskSpacePercentage))
                                .stroke(
                                    LinearGradient(
                                        colors: [.red, .orange],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                                )
                                .frame(width: 120, height: 120)
                                .rotationEffect(Angle(degrees: -90))
                            
                            VStack(spacing: 4) {
                                Text("\(Int(usedDiskSpacePercentage * 100))%")
                                    .font(.title2)
                                    .bold()
                                Text("Used")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Circle().fill(Color.orange).frame(width: 10, height: 10)
                                Text("Free Space: \(freeDiskSpace)")
                                    .font(.body)
                            }
                            HStack {
                                Circle().fill(Color.red).frame(width: 10, height: 10)
                                Text("Total Capacity: \(totalDiskSpace)")
                                    .font(.body)
                            }
                            HStack {
                                Circle().fill(Color.blue).frame(width: 10, height: 10)
                                Text("macOS Version: \(macOSVersion)")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                    )
                }
                
                // Features Grid
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Tools")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        FeatureCard(
                            title: "App Uninstaller",
                            description: "Completely remove any application and all its hidden support files, logs, and preferences.",
                            icon: "trash.fill",
                            color: .red
                        )
                        FeatureCard(
                            title: "Orphan Finder",
                            description: "Detect and sweep away orphaned directories from apps that are no longer installed on your Mac.",
                            icon: "folder.badge.minus",
                            color: .orange
                        )
                        FeatureCard(
                            title: "Developer Caches",
                            description: "Instantly reclaim gigabytes by cleaning DerivedData, packages, caches, and unused docker images.",
                            icon: "hammer.fill",
                            color: .blue
                        )
                        FeatureCard(
                            title: "System Tweaks",
                            description: "Speed up Dock animations, key repeat rate, Finder features, and customize screenshooting.",
                            icon: "slider.horizontal.3",
                            color: .green
                        )
                    }
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        .onAppear {
            updateDiskMetrics()
        }
    }
    
    private func updateDiskMetrics() {
        let fileManager = FileManager.default
        let path = "/"
        do {
            let values = try fileManager.attributesOfFileSystem(forPath: path)
            if let totalBytes = values[.systemSize] as? Int64,
               let freeBytes = values[.systemFreeSize] as? Int64 {
                let usedBytes = totalBytes - freeBytes
                
                let formatter = ByteCountFormatter()
                formatter.countStyle = .file
                formatter.allowedUnits = [.useGB, .useTB]
                
                totalDiskSpace = formatter.string(fromByteCount: totalBytes)
                freeDiskSpace = formatter.string(fromByteCount: freeBytes)
                usedDiskSpacePercentage = Double(usedBytes) / Double(totalBytes)
            }
        } catch {
            AppLogger.shared.log("Error reading disk metrics: \(error.localizedDescription)")
        }
    }
}

struct FeatureCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        )
    }
}
