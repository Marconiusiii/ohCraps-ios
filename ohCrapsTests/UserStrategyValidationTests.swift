import XCTest
@testable import ohCraps

final class UserStrategyValidationTests: XCTestCase {
	func testWhitespaceOnlyRequiredFieldsAreRejected() {
		let issues = UserStrategyValidation.issues(
			for: UserStrategyDraft(name: "   ", buyIn: "\n", tableMinimum: "\t", steps: "  ", notes: "", credit: ""),
			currentStrategyCount: 0,
			creatingNewStrategy: true
		)

		XCTAssertEqual(issues.compactMap(\.field), [.name, .buyIn, .tableMin, .steps])
	}

	func testValuesAtEveryLengthLimitAreAccepted() {
		let issues = UserStrategyValidation.issues(
			for: UserStrategyDraft(
				name: String(repeating: "n", count: UserStrategyValidation.maximumNameLength),
				buyIn: String(repeating: "b", count: UserStrategyValidation.maximumBuyInLength),
				tableMinimum: String(repeating: "t", count: UserStrategyValidation.maximumTableMinimumLength),
				steps: String(repeating: "s", count: UserStrategyValidation.maximumStepsLength),
				notes: String(repeating: "o", count: UserStrategyValidation.maximumNotesLength),
				credit: String(repeating: "c", count: UserStrategyValidation.maximumCreditLength)
			),
			currentStrategyCount: UserStrategyValidation.maximumStrategyCount - 1,
			creatingNewStrategy: true
		)

		XCTAssertTrue(issues.isEmpty)
	}

	func testValuesOverLimitsAndStrategyCountAreRejected() {
		let issues = UserStrategyValidation.issues(
			for: UserStrategyDraft(
				name: String(repeating: "n", count: UserStrategyValidation.maximumNameLength + 1),
				buyIn: "10",
				tableMinimum: "5",
				steps: "1. Start",
				notes: "",
				credit: ""
			),
			currentStrategyCount: UserStrategyValidation.maximumStrategyCount,
			creatingNewStrategy: true
		)

		XCTAssertTrue(issues.contains { $0.field == .name })
		XCTAssertTrue(issues.contains(.strategyLimit(maximum: UserStrategyValidation.maximumStrategyCount)))
	}

	func testEditingAtStrategyLimitRemainsAllowed() {
		let issues = UserStrategyValidation.issues(
			for: UserStrategyDraft(name: "Name", buyIn: "10", tableMinimum: "5", steps: "1. Start", notes: "", credit: ""),
			currentStrategyCount: UserStrategyValidation.maximumStrategyCount,
			creatingNewStrategy: false
		)

		XCTAssertTrue(issues.isEmpty)
	}
}
