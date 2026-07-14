import SwiftUI

struct mainsidebarview: View {
    @State private var selectedItem: NavigationItem? = .dashboard
    
    var body: some View {
        VStack(spacing: 0) {
            NavigationSplitView {
                List(selection: $selectedItem) {
                    Section("General") {
                        sidebarLink(for: .dashboard)
                    }
                    
                    Section("Applications") {
                        sidebarLink(for: .appUninstaller)
                        sidebarLink(for: .orphanScanner)
                        sidebarLink(for: .appLipo)
                        sidebarLink(for: .brewExplorer)
                    }
                    
                    Section("Storage Clean") {
                        sidebarLink(for: .devCaches)
                        sidebarLink(for: .largeFiles)
                        sidebarLink(for: .hiddenFiles)
                    }
                    
                    Section("System & Advanced") {
                        sidebarLink(for: .serviceManager)
                        sidebarLink(for: .systemTweaks)
                        sidebarLink(for: .quarantineStripper)
                        sidebarLink(for: .dnsEditor)
                        sidebarLink(for: .launchServices)
                        sidebarLink(for: .sdkSwitcher)
                    }
                }
                .listStyle(.sidebar)
                .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
            } detail: {
                if let item = selectedItem {
                    switch item {
                    case .dashboard:
                        dashboardview()
                    case .appUninstaller:
                        appuninstallerview()
                    case .orphanScanner:
                        orphanscannerview()
                    case .serviceManager:
                        launchdmanagerview()
                    case .devCaches:
                        cacheprunerview()
                    case .systemTweaks:
                        systemtweakerview()
                    case .quarantineStripper:
                        quarantinestripperview()
                    case .dnsEditor:
                        dnseditorview()
                    case .launchServices:
                        launchservicesview()
                    case .hiddenFiles:
                        hiddenfileview()
                    case .appLipo:
                        applipoview()
                    case .largeFiles:
                        largefilesview()
                    case .brewExplorer:
                        brewmanagerview()
                    case .sdkSwitcher:
                        sdkmanagerview()
                    default:
                        placeholderView(for: item)
                    }
                } else {
                    VStack {
                        Image(systemName: "square.dashed")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 8)
                        Text("No Tool Selected")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            statusbarview()
        }
    }
    
    @ViewBuilder
    private func placeholderView(for item: NavigationItem) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: item.iconName)
                    .font(.system(size: 40))
                    .foregroundStyle(Color.accentColor)
            }
            
            VStack(spacing: 8) {
                Text(item.title)
                    .font(.title2)
                    .bold()
                
                Text("This module is scheduled for implementation in a later phase.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    @ViewBuilder
    private func sidebarLink(for item: NavigationItem) -> some View {
        NavigationLink(value: item) {
            HStack(spacing: 10) {
                Image(systemName: item.iconName)
                    .font(.body)
                    .frame(width: 18, alignment: .center)
                Text(item.title)
                    .font(.body)
            }
        }
        .padding(.vertical, 4)
    }
}
