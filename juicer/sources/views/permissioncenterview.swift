import SwiftUI
import AppKit

struct permissioncenterview: View {
    @StateObject private var manager = permissioncentermanager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            JuicerFeatureHeader(title: "Permission Center", subtitle: "Review and request the macOS access Juicer uses for its tools and menu bar extensions.", icon: "lock.shield", refreshing: false, action: manager.refresh)

            HStack {
                Label("macOS will always ask for protected access", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Request Available") { manager.requestAll() }
                    .buttonStyle(.borderedProminent)
                Button("Open Privacy Settings") { manager.openPrivacySettings() }
                    .buttonStyle(.bordered)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)

            List(juicerpermissionkind.allCases) { permission in
                permissionRow(permission)
            }
            .listStyle(.inset)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { manager.refresh() }
    }

    private func permissionRow(_ permission: juicerpermissionkind) -> some View {
        HStack(spacing: 12) {
            Image(systemName: permission.icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 3) {
                Text(permission.title).font(.headline)
                Text(permission.detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(manager.statuses[permission] ?? "checking")
                .font(.caption.weight(.semibold))
                .foregroundStyle(statusColor(manager.statuses[permission]))
            Button("Request") { manager.request(permission) }
                .buttonStyle(.bordered)
                .disabled(manager.statuses[permission] == "allowed")
            Button("Settings") { manager.openSettings(for: permission) }
                .buttonStyle(.bordered)
        }
        .padding(.vertical, 6)
    }

    private func statusColor(_ status: String?) -> Color {
        switch status {
        case "allowed": return .green
        case "denied", "restricted": return .red
        default: return .orange
        }
    }
}
