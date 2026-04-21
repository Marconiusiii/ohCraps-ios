import Foundation
import Combine

@MainActor
final class FavoritesStore: ObservableObject {
	@Published private(set) var favoriteIDs: Set<UUID> = []

	private let storeKey = "favoriteStrategyIDs"

	init() {
		load()
	}

	func toggle(_ id: UUID) {
		if favoriteIDs.contains(id) {
			favoriteIDs.remove(id)
		} else {
			favoriteIDs.insert(id)
		}
		save()
	}

	func isFavorite(_ id: UUID) -> Bool {
		favoriteIDs.contains(id)
	}

	private func load() {
		guard let raw = UserDefaults.standard.array(forKey: storeKey) as? [String] else { return }
		favoriteIDs = Set(raw.compactMap { UUID(uuidString: $0) })
	}

	private func save() {
		let raw = favoriteIDs.map { $0.uuidString }
		UserDefaults.standard.set(raw, forKey: storeKey)
	}
}
