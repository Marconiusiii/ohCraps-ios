import Foundation
import SwiftUI
import Combine

@MainActor
final class UserStrategyStore: ObservableObject {

	@Published private(set) var strategies: [UserStrategy] = []

	private let storageKey = "userStrategies"

	init() {
		load()
	}

	func add(_ strategy: UserStrategy) {
		strategies.append(strategy)
		save()
	}

	func update(
		id: UUID,
		name: String,
		buyIn: String,
		tableMinimum: String,
		steps: String,
		notes: String,
		credit: String
	) {
		guard let index = strategies.firstIndex(where: { $0.id == id }) else {
			return
		}

		let existing = strategies[index]
		let updatedDate = Date()
		let shouldRequireResubmission = existing.isSubmitted

		strategies[index] = UserStrategy(
			id: existing.id,
			name: name,
			buyIn: buyIn,
			tableMinimum: tableMinimum,
			steps: steps,
			notes: notes,
			credit: credit,
			dateCreated: existing.dateCreated,
			dateLastEdited: updatedDate,
			isSubmitted: shouldRequireResubmission ? false : existing.isSubmitted,
			hasBeenSubmitted: existing.hasBeenSubmitted || existing.isSubmitted
		)

		save()
	}


	func delete(_ strategy: UserStrategy) {
		strategies.removeAll { $0.id == strategy.id }
		save()
	}
	func setSubmitted(id: UUID, isSubmitted: Bool) {
		guard let index = strategies.firstIndex(where: { $0.id == id }) else {
			return
		}

		let existing = strategies[index]

		strategies[index] = UserStrategy(
			id: existing.id,
			name: existing.name,
			buyIn: existing.buyIn,
			tableMinimum: existing.tableMinimum,
			steps: existing.steps,
			notes: existing.notes,
			credit: existing.credit,
			dateCreated: existing.dateCreated,
			dateLastEdited: existing.dateLastEdited,
			isSubmitted: isSubmitted,
			hasBeenSubmitted: existing.hasBeenSubmitted || isSubmitted
		)

		save()
	}

	private func save() {
		do {
			let data = try JSONEncoder().encode(strategies)
			UserDefaults.standard.set(data, forKey: storageKey)
		} catch {
			// Fail silently — user data should never crash the app
		}
	}

	private func load() {
		guard
			let data = UserDefaults.standard.data(forKey: storageKey),
			let decoded = try? JSONDecoder().decode([UserStrategy].self, from: data)
		else {
			return
		}

		strategies = decoded
	}
}
