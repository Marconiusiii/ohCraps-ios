import XCTest
@testable import ohCraps

final class UserStrategyStepParserTests: XCTestCase {
	func testPeriodEnumerationIsRemoved() {
		XCTAssertEqual(
			UserStrategyStepParser.displayContent(from: "1. Place the pass-line bet"),
			"Place the pass-line bet"
		)
	}

	func testParenthesisEnumerationIsRemoved() {
		XCTAssertEqual(
			UserStrategyStepParser.displayContent(from: "12) Take odds"),
			"Take odds"
		)
	}

	func testUnnumberedStepIsUnchanged() {
		XCTAssertEqual(
			UserStrategyStepParser.displayContent(from: "Take odds"),
			"Take odds"
		)
	}

	func testDecimalValueIsNotTreatedAsEnumeration() {
		XCTAssertEqual(
			UserStrategyStepParser.displayContent(from: "1.5 units on the line"),
			"1.5 units on the line"
		)
	}

	func testIrregularUserNumberIsRemovedBeforeAutomaticNumbering() {
		XCTAssertEqual(
			UserStrategyStepParser.orderedContent(from: "27. Press the bet"),
			"Press the bet"
		)
	}

	func testSharingAppliesOnlyOneSetOfNumbers() {
		let strategy = UserStrategy(
			name: "Test",
			buyIn: "$100",
			tableMinimum: "$5",
			steps: "7. Place the pass-line bet\n10) Take odds",
			notes: "",
			credit: ""
		)

		let sharedText = StrategyShareFormatter.shareText(for: strategy)

		XCTAssertTrue(sharedText.contains("1. Place the pass-line bet\n2. Take odds"))
		XCTAssertFalse(sharedText.contains("1. 7."))
		XCTAssertFalse(sharedText.contains("2. 10)"))
	}
}
