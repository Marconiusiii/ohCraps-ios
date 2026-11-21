import Foundation

enum AgeAssurancePolicy {
	static let minimumSupportedVersion = OperatingSystemVersion(majorVersion: 26, minorVersion: 2, patchVersion: 0)
	static let ageGates = (13, 16, 18)

	struct RegulatoryRequirements: Equatable {
		let declaredAgeRangeRequired: Bool
		let significantChangeRequiresAdultNotification: Bool
		let significantChangeRequiresParentalConsent: Bool
	}

	static func supportsRegionalEligibility(on version: OperatingSystemVersion) -> Bool {
		if version.majorVersion != minimumSupportedVersion.majorVersion {
			return version.majorVersion > minimumSupportedVersion.majorVersion
		}
		if version.minorVersion != minimumSupportedVersion.minorVersion {
			return version.minorVersion > minimumSupportedVersion.minorVersion
		}
		return version.patchVersion >= minimumSupportedVersion.patchVersion
	}

	static func shouldRequestAgeRange(for requirements: RegulatoryRequirements) -> Bool {
		requirements.declaredAgeRangeRequired
	}
}
