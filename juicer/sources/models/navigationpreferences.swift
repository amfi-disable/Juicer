import Foundation

final class navigationpreferences: ObservableObject {
    static let shared = navigationpreferences()

    @Published private(set) var favorites: [NavigationItem] = []
    @Published private(set) var recent: [NavigationItem] = []

    private let favoritesKey = "juicer.navigation.favorites"
    private let recentKey = "juicer.navigation.recent"

    private init() {
        favorites = read(favoritesKey)
        recent = read(recentKey)
    }

    func isFavorite(_ item: NavigationItem) -> Bool { favorites.contains(item) }

    func toggleFavorite(_ item: NavigationItem) {
        if let index = favorites.firstIndex(of: item) {
            favorites.remove(at: index)
        } else {
            favorites.append(item)
        }
        save(favorites, key: favoritesKey)
    }

    func record(_ item: NavigationItem) {
        recent.removeAll { $0 == item }
        recent.insert(item, at: 0)
        recent = Array(recent.prefix(8))
        save(recent, key: recentKey)
    }

    func clearRecent() {
        recent = []
        save(recent, key: recentKey)
    }

    private func read(_ key: String) -> [NavigationItem] {
        (UserDefaults.standard.stringArray(forKey: key) ?? []).compactMap(NavigationItem.init(rawValue:))
    }

    private func save(_ items: [NavigationItem], key: String) {
        UserDefaults.standard.set(items.map(\.rawValue), forKey: key)
    }
}
