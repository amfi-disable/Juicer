import SwiftUI
import AppKit

struct helpview: View {
    @State private var searchText = ""

    private let sections: [helpsection] = [
        helpsection(title: "Getting Started", icon: "sparkles", entries: [
            helpentry(title: "Main window", detail: "Choose a workspace from the App Hub, then select a tool in its sidebar. Use Cmd+, for Settings and Cmd+? for this guide."),
            helpentry(title: "Menu bar", detail: "Juicer adds optional status items on the right side of the macOS menu bar. Click Open Juicer Dashboard to activate and focus the main window."),
            helpentry(title: "Permissions", detail: "Open Permission Center from Utilities or Settings > Control Center. Native prompts are requested where macOS permits them; protected access such as Full Disk Access is enabled in System Settings."),
        ]),
        helpsection(title: "Keyboard Shortcuts", icon: "command", entries: [
            helpentry(title: "Cmd + ,", detail: "Open Juicer Settings."),
            helpentry(title: "Cmd + ?", detail: "Open the Help Manual."),
            helpentry(title: "Cmd + R", detail: "Refresh the selected tool."),
            helpentry(title: "Cmd + 1…9", detail: "Jump to the primary navigation tools."),
            helpentry(title: "Cmd + Shift + U", detail: "Open Utilities Settings."),
        ]),
        helpsection(title: "Safe Cleanup", icon: "checkmark.shield", entries: [
            helpentry(title: "Review before deleting", detail: "Use previews, ignored paths, and the confirmation setting before running cleanup or uninstall actions."),
            helpentry(title: "Undo history", detail: "Deleted items moved through Juicer's safe deletion flows can be reviewed in Undo Deletion History when supported by the tool."),
            helpentry(title: "Protected locations", detail: "System locations are excluded by default. Full Disk Access expands visibility but does not remove confirmation safeguards."),
        ]),
        helpsection(title: "Troubleshooting", icon: "stethoscope", entries: [
            helpentry(title: "Better Cmd-Tab is empty", detail: "Grant Accessibility and Screen Recording, then relaunch Juicer. Screen Recording is needed for thumbnails; Accessibility is needed to control and paste into other apps."),
            helpentry(title: "The menu-bar item is missing", detail: "Open Cmd+, > Control Center and enable the relevant menu-bar extension. macOS may also hide status items behind the menu-bar overflow area."),
            helpentry(title: "A permission still says needs approval", detail: "Enable Juicer in System Settings > Privacy & Security, then quit and reopen Juicer. macOS does not allow apps to silently grant protected permissions to themselves."),
            helpentry(title: "The main window is not visible", detail: "Click a menu-bar item and choose Open Juicer Dashboard, or use Cmd+, from the application menu when Juicer is active."),
        ]),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Juicer Help", systemImage: "questionmark.circle.fill")
                    .font(.title2.bold())
                Spacer()
                TextField("Search help", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 220)
            }
            .padding(20)
            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    ForEach(filteredSections) { section in
                        VStack(alignment: .leading, spacing: 10) {
                            Label(section.title, systemImage: section.icon).font(.headline)
                            ForEach(section.entries) { entry in
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(entry.title).font(.subheadline.bold())
                                    Text(entry.detail).font(.caption).foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .background(Color(NSColor.controlBackgroundColor).opacity(0.45), in: RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    if filteredSections.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    }
                }
                .padding(20)
            }
        }
        .frame(minWidth: 620, minHeight: 500)
    }

    private var filteredSections: [helpsection] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return sections }
        let query = searchText.lowercased()
        return sections.compactMap { section in
            let entries = section.entries.filter { entry in
                entry.title.lowercased().contains(query) || entry.detail.lowercased().contains(query)
            }
            return entries.isEmpty ? nil : helpsection(title: section.title, icon: section.icon, entries: entries)
        }
    }
}

private struct helpsection: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let entries: [helpentry]
}

private struct helpentry: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}
