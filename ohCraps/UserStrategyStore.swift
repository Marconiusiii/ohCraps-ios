import Foundation
import SwiftUI
import Combine

enum UserStrategyPersistenceIssue: Identifiable, Equatable {
	case loadFailed
	case saveFailed

	var id: Self { self }

	var title: String {
		switch self {
		case .loadFailed: return "Couldn't Load Strategies"
		case .saveFailed: return "Couldn't Save Strategies"
		}
	}

	var message: String {
		switch self {
		case .loadFailed:
			return "Your saved strategies couldn't be loaded. Try again before making changes."
		case .saveFailed:
			return "Your latest strategy changes couldn't be saved. Try again."
		}
	}
}

@MainActor
final class UserStrategyStore: ObservableObject {

	@Published private(set) var strategies: [UserStrategy] = []
	@Published var persistenceIssue: UserStrategyPersistenceIssue?

	private let storageKey = "userStrategies"
	private let userDefaults: UserDefaults
	private let encodeStrategies: @Sendable ([UserStrategy]) throws -> Data
	private let decodeStrategies: @Sendable (Data) throws -> [UserStrategy]
	private let persistenceQueue = DispatchQueue(
		label: "com.ohcraps.userstrategystore.persistence",
		qos: .utility
	)
	private var pendingSaveSnapshot: [UserStrategy]?
	private var isSaveInFlight = false
	private var persistenceBlockedByLoadFailure = false

	init(
		userDefaults: UserDefaults = .standard,
		encodeStrategies: @escaping @Sendable ([UserStrategy]) throws -> Data = { try JSONEncoder().encode($0) },
		decodeStrategies: @escaping @Sendable (Data) throws -> [UserStrategy] = { try JSONDecoder().decode([UserStrategy].self, from: $0) }
	) {
		self.userDefaults = userDefaults
		self.encodeStrategies = encodeStrategies
		self.decodeStrategies = decodeStrategies
		load()
	}

	@discardableResult
	func add(_ strategy: UserStrategy) -> Bool {
		guard canModifyStrategies else { return false }
		strategies.append(strategy)
		save()
		return true
	}

	@discardableResult
	func update(
		id: UUID,
		name: String,
		buyIn: String,
		tableMinimum: String,
		steps: String,
		notes: String,
		credit: String
	) -> Bool {
		guard canModifyStrategies else { return false }
		guard let index = strategies.firstIndex(where: { $0.id == id }) else {
			return false
		}

		let existing = strategies[index]
		let didChange =
			existing.name != name ||
			existing.buyIn != buyIn ||
			existing.tableMinimum != tableMinimum ||
			existing.steps != steps ||
			existing.notes != notes ||
			existing.credit != credit
		guard didChange else {
			return true
		}

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
		return true
	}


	@discardableResult
	func delete(_ strategy: UserStrategy) -> Bool {
		guard canModifyStrategies else { return false }
		let oldCount = strategies.count
		strategies.removeAll { $0.id == strategy.id }
		guard strategies.count != oldCount else {
			return false
		}
		save()
		return true
	}

	@discardableResult
	func setSubmitted(id: UUID, isSubmitted: Bool) -> Bool {
		guard canModifyStrategies else { return false }
		guard let index = strategies.firstIndex(where: { $0.id == id }) else {
			return false
		}

		let existing = strategies[index]
		guard existing.isSubmitted != isSubmitted else {
			return true
		}

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
		return true
	}

	func retryPersistence() {
		switch persistenceIssue {
		case .loadFailed:
			load()
		case .saveFailed:
			persistenceIssue = nil
			save()
		case nil:
			break
		}
	}

	func dismissPersistenceIssue() {
		persistenceIssue = nil
	}

	private var canModifyStrategies: Bool {
		guard !persistenceBlockedByLoadFailure else {
			persistenceIssue = .loadFailed
			return false
		}
		return true
	}

	private func save() {
		pendingSaveSnapshot = strategies
		scheduleNextSaveIfNeeded()
	}

	private func scheduleNextSaveIfNeeded() {
		guard !isSaveInFlight, let snapshot = pendingSaveSnapshot else {
			return
		}

		isSaveInFlight = true
		pendingSaveSnapshot = nil
		let encodeStrategies = self.encodeStrategies

		persistenceQueue.async {
			let encodedData: Data?
			do {
				encodedData = try encodeStrategies(snapshot)
			} catch {
				encodedData = nil
			}

			Task { @MainActor in
				if let encodedData {
					let existing = self.userDefaults.data(forKey: self.storageKey)
					if existing != encodedData {
						self.userDefaults.set(encodedData, forKey: self.storageKey)
					}
				} else {
					self.persistenceIssue = .saveFailed
				}
				self.isSaveInFlight = false
				self.scheduleNextSaveIfNeeded()
			}
		}
	}

	private func load() {
		guard let data = userDefaults.data(forKey: storageKey) else {
			persistenceBlockedByLoadFailure = false
			persistenceIssue = nil
			return
		}

		do {
			strategies = try decodeStrategies(data)
			persistenceBlockedByLoadFailure = false
			persistenceIssue = nil
		} catch {
			persistenceBlockedByLoadFailure = true
			persistenceIssue = .loadFailed
		}
	}
}
