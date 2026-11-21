import Combine
import XCTest
@testable import ohCraps

final class UserStrategyStoreTests: XCTestCase {
	private var suiteName: String!
	private var defaults: UserDefaults!

	override func setUp() {
		super.setUp()
		suiteName = "ohCrapsTests.\(UUID().uuidString)"
		defaults = UserDefaults(suiteName: suiteName)
	}

	override func tearDown() {
		defaults.removePersistentDomain(forName: suiteName)
		defaults = nil
		suiteName = nil
		super.tearDown()
	}

	func testValidStrategiesLoad() throws {
		let strategy = UserStrategy(name: "Test", buyIn: "100", tableMinimum: "5", steps: "Start", notes: "", credit: "")
		defaults.set(try JSONEncoder().encode([strategy]), forKey: "userStrategies")

		let store = UserStrategyStore(userDefaults: defaults)

		XCTAssertEqual(store.strategies.map(\.id), [strategy.id])
		XCTAssertNil(store.persistenceIssue)
	}

	func testCorruptDataIsReportedAndNotOverwritten() {
		let corruptData = Data("not json".utf8)
		defaults.set(corruptData, forKey: "userStrategies")
		let store = UserStrategyStore(userDefaults: defaults)

		let added = store.add(UserStrategy(name: "Test", buyIn: "100", tableMinimum: "5", steps: "Start", notes: "", credit: ""))

		XCTAssertFalse(added)
		XCTAssertEqual(store.persistenceIssue, .loadFailed)
		XCTAssertEqual(defaults.data(forKey: "userStrategies"), corruptData)
	}

	func testEncodingFailureIsReported() async {
		let issueExpectation = expectation(description: "Save issue reported")
		var cancellable: AnyCancellable?
		let store = UserStrategyStore(
			userDefaults: defaults,
			encodeStrategies: { _ in throw CocoaError(.fileWriteUnknown) }
		)
		cancellable = store.$persistenceIssue.dropFirst().sink { issue in
			if issue == .saveFailed {
				issueExpectation.fulfill()
			}
		}

		XCTAssertTrue(store.add(UserStrategy(name: "Test", buyIn: "100", tableMinimum: "5", steps: "Start", notes: "", credit: "")))
		await fulfillment(of: [issueExpectation], timeout: 2)
		withExtendedLifetime(cancellable) {}
	}
}
