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

	func delete(_ strategy: UserStrategy) {
		strategies.removeAll { $0.id == strategy.id }
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

