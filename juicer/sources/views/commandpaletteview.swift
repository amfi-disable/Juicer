import SwiftUI

struct commandpaletteview: View {
    let onSelect: (NavigationItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @AppStorage("juicer.navigation.searchHistory") private var searchHistory = ""
    @FocusState private var searchFocused: Bool

    private var results: [NavigationItem] {
        let items = NavigationItem.allCases
        guard !query.isEmpty else {
            let recent = searchHistory.split(separator: ",").compactMap { NavigationItem(rawValue: String($0)) }
            return recent + items.filter { !recent.contains($0) }
        }
        return items.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.rawValue.localizedCaseInsensitiveContains(query) ||
            $0.workspace.title.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "command")
                    .foregroundStyle(.tint)
                TextField("Search every Juicer tool…", text: $query)
                    .textFieldStyle(.plain)
                    .focused($searchFocused)
                    .onSubmit { selectFirst() }
                Text("esc")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            .padding(14)

            Divider()

            List(results) { item in
                Button {
                    remember(item)
                    onSelect(item)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: item.iconName)
                            .frame(width: 24)
                            .foregroundStyle(.tint)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                            Text(item.workspace.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "return")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .listStyle(.inset)
        }
        .frame(width: 520, height: 520)
        .onAppear { searchFocused = true }
        .onExitCommand { dismiss() }
    }

    private func selectFirst() {
        guard let item = results.first else { return }
        remember(item)
        onSelect(item)
        dismiss()
    }

    private func remember(_ item: NavigationItem) {
        var values = searchHistory.split(separator: ",").map(String.init)
        values.removeAll { $0 == item.rawValue }
        values.insert(item.rawValue, at: 0)
        searchHistory = values.prefix(8).joined(separator: ",")
    }
}
