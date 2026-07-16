import SwiftUI
import AppKit

struct deletionhistoryview: View {
    @StateObject private var undoManager = DeletionUndoManager.shared
    @State private var selectedBackup: DeletionBackup?
    @State private var showConfirmDelete = false
    @State private var resultMessage: String = ""
    @State private var showResult = false

    var body: some View {
        VStack(spacing: 0) {
            headerSection()
            Divider()

            if undoManager.backups.isEmpty {
                emptyStatePlaceholder()
            } else {
                backupsList()
            }
            
            Divider()
            footerDetailsBar()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            undoManager.loadBackups()
        }
        .alert("Confirm Permanent Deletion", isPresented: $showConfirmDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let backup = selectedBackup {
                    undoManager.deleteBackupPermanently(backup)
                    selectedBackup = nil
                }
            }
        } message: {
            if let backup = selectedBackup {
                Text("Are you sure you want to permanently delete '\(backup.name)'? This action cannot be undone.\nSize: \(formatBytes(backup.sizeBytes))")
            }
        }
        .alert("Done", isPresented: $showResult) {
            Button("OK") {}
        } message: {
            Text(resultMessage)
        }
    }

    // MARK: - Header
    @ViewBuilder
    private func headerSection() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Deletion Undo History")
                    .font(.title2).bold()
                Text("Review and roll back files trashed by Juicer. Items are kept for 3 days before auto-purging.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            
            if !undoManager.backups.isEmpty {
                Button("Clear Cabinet Safely") {
                    for backup in undoManager.backups {
                        undoManager.deleteBackupPermanently(backup)
                    }
                    selectedBackup = nil
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }

    // MARK: - Empty State
    @ViewBuilder
    private func emptyStatePlaceholder() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48)).foregroundStyle(.secondary)
            Text("No Deletion History").font(.headline).foregroundStyle(.secondary)
            Text("When you delete application caches, large files, or directories, they are temporarily held here in case you need to undo.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - List
    @ViewBuilder
    private func backupsList() -> some View {
        List(undoManager.backups) { backup in
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.orange.opacity(0.12))
                        .frame(width: 32, height: 32)
                    Image(systemName: "folder.badge.gearshape")
                        .font(.caption).foregroundColor(.orange)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(backup.name).font(.headline)
                    Text("Original: \(backup.originalPath)").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    Text("Trashed: \(formatDate(backup.timestamp))").font(.caption2).foregroundStyle(.tertiary)
                }

                Spacer()

                Text(formatBytes(backup.sizeBytes))
                    .font(.subheadline).bold().foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Button("Undo") {
                        undoManager.restoreBackup(backup) { success, msg in
                            resultMessage = msg
                            showResult = true
                            if success {
                                selectedBackup = nil
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)

                    Button(action: {
                        selectedBackup = backup
                        showConfirmDelete = true
                    }) {
                        Image(systemName: "trash.fill").foregroundColor(.red)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .onTapGesture {
                selectedBackup = backup
            }
        }
        .listStyle(.inset)
    }

    // MARK: - Footer details bar
    @ViewBuilder
    private func footerDetailsBar() -> some View {
        HStack {
            if let backup = selectedBackup {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Selected: \(backup.name)").bold().font(.subheadline)
                    Text("Backup path: \(backup.backupPath)").font(.caption2).foregroundColor(.secondary)
                        .lineLimit(1).truncationMode(.middle)
                }
                Spacer()
                Button("Reveal in Finder") {
                    NSWorkspace.shared.selectFile(backup.backupPath, inFileViewerRootedAtPath: "")
                }
                .buttonStyle(.bordered)
            } else {
                Text("Select an item to view backup storage coordinates.")
                    .font(.caption).foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
        .frame(height: 48)
    }

    // MARK: - Helpers
    private func formatBytes(_ bytes: Int64) -> String {
        guard bytes >= 0 else { return "—" }
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f.string(fromByteCount: bytes)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
