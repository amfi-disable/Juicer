import SwiftUI

struct commandpaletteview: View {
    let onSelect: (NavigationItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @FocusState private var searchFocused: Bool

    private var results: [NavigationItem] {
        let items = NavigationItem.allCases
        guard !query.isEmpty else { return items }
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
        onSelect(item)
        dismiss()
    }
}
