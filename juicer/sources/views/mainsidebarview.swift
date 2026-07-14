import SwiftUI

struct mainsidebarview: View {
    @State private var selectedItem: NavigationItem? = .dashboard
    
    var body: some View {
        VStack(spacing: 0) {
            NavigationSplitView {
                List(NavigationItem.allCases, selection: $selectedItem) { item in
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
        .background(Color(NSColor.underlyingWindowBackgroundColor))
    }
}
