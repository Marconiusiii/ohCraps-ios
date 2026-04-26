import Foundation
import Combine

@MainActor
final class StrategyNotesStore: ObservableObject {
	@Published private(set) var notesByID: [UUID: String] = [:]

	private let storeKey = "coreStrategyNotes"

	init() {
		load()
	}

	func note(for id: UUID) -> String {
		notesByID[id] ?? ""
	}

	func setNote(_ note: String, for id: UUID) {
		let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)

		if trimmed.isEmpty {
			notesByID.removeValue(forKey: id)
		} else {
			notesByID[id] = note
		}

		save()
	}

	private func load() {
		guard let raw = UserDefaults.standard.dictionary(forKey: storeKey) as? [String: String] else {
			return
		}

		var loaded: [UUID: String] = [:]

		for (key, value) in raw {
			if let id = UUID(uuidString: key) {
				loaded[id] = value
			}
		}

		notesByID = loaded
	}

	private func save() {
		let raw = Dictionary(
			uniqueKeysWithValues: notesByID.map { id, note in
				(id.uuidString, note)
			}
		)

		UserDefaults.standard.set(raw, forKey: storeKey)
	}
}
