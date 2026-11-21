import XCTest
@testable import ohCraps

final class AgeAssurancePolicyTests: XCTestCase {
	func testRegionalEligibilityStartsAtIOS262() {
		XCTAssertFalse(AgeAssurancePolicy.supportsRegionalEligibility(on: .init(majorVersion: 26, minorVersion: 1, patchVersion: 9)))
		XCTAssertTrue(AgeAssurancePolicy.supportsRegionalEligibility(on: .init(majorVersion: 26, minorVersion: 2, patchVersion: 0)))
		XCTAssertTrue(AgeAssurancePolicy.supportsRegionalEligibility(on: .init(majorVersion: 27, minorVersion: 0, patchVersion: 0)))
	}

	func testAgeRangeIsRequestedOnlyWhenRequired() {
		let notRequired = AgeAssurancePolicy.RegulatoryRequirements(
			declaredAgeRangeRequired: false,
			significantChangeRequiresAdultNotification: true,
			significantChangeRequiresParentalConsent: true
		)
		let required = AgeAssurancePolicy.RegulatoryRequirements(
			declaredAgeRangeRequired: true,
			significantChangeRequiresAdultNotification: false,
			significantChangeRequiresParentalConsent: false
		)

		XCTAssertFalse(AgeAssurancePolicy.shouldRequestAgeRange(for: notRequired))
		XCTAssertTrue(AgeAssurancePolicy.shouldRequestAgeRange(for: required))
	}

	func testConfiguredAgeGatesRemainThirteenSixteenAndEighteen() {
		XCTAssertEqual(AgeAssurancePolicy.ageGates.0, 13)
		XCTAssertEqual(AgeAssurancePolicy.ageGates.1, 16)
		XCTAssertEqual(AgeAssurancePolicy.ageGates.2, 18)
	}
}
