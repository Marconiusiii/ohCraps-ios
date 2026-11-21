import SwiftUI
#if canImport(DeclaredAgeRange)
import DeclaredAgeRange
#endif

@main
struct OhCrapsApp: App {

	init() {
		let appearance = UITabBarAppearance()
		appearance.configureWithOpaqueBackground()

		// Wood / rail color (matches your AppTheme.tabBarBackground)
		appearance.backgroundColor = UIColor(
			red: 0.18,
			green: 0.10,
			blue: 0.06,
			alpha: 1.0
		)

		// Active tab text
		appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
			.foregroundColor: UIColor.white
		]

		// Inactive tab text
		appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
			.foregroundColor: UIColor.white.withAlphaComponent(0.7)
		]

		// Apply everywhere
		UITabBar.appearance().standardAppearance = appearance
		UITabBar.appearance().scrollEdgeAppearance = appearance
	}

	var body: some Scene {
		WindowGroup {
			RootView()
				.background {
					AgeAssuranceComplianceView()
				}
		}
	}
}

private struct AgeAssuranceComplianceView: View {
	var body: some View {
		if #available(iOS 26.2, *) {
			DeclaredAgeRangeComplianceTask()
		}
	}
}

#if canImport(DeclaredAgeRange)
@available(iOS 26.2, *)
private struct DeclaredAgeRangeComplianceTask: View {
	@Environment(\.requestAgeRange) private var requestAgeRange
	@Environment(\.scenePhase) private var scenePhase
	@State private var hasCompletedAgeRangeCheck = false
	@State private var isCheckingAgeRange = false

	var body: some View {
		Color.clear
			.frame(width: 0, height: 0)
			.accessibilityHidden(true)
			.task(id: scenePhase) {
				guard scenePhase == .active else { return }
				await checkDeclaredAgeRangeIfRequired()
			}
	}

	private func checkDeclaredAgeRangeIfRequired() async {
		guard !hasCompletedAgeRangeCheck, !isCheckingAgeRange else { return }
		isCheckingAgeRange = true
		defer { isCheckingAgeRange = false }

		do {
			if #available(iOS 26.4, *) {
				let features = try await AgeRangeService.shared.requiredRegulatoryFeatures
				let requirements = AgeAssurancePolicy.RegulatoryRequirements(
					declaredAgeRangeRequired: features.contains(.declaredAgeRangeRequired),
					significantChangeRequiresAdultNotification: features.contains(.significantAppChangeRequiresAdultNotification),
					significantChangeRequiresParentalConsent: features.contains(.significantAppChangeRequiresParentalConsent)
				)
				guard AgeAssurancePolicy.shouldRequestAgeRange(for: requirements) else {
					hasCompletedAgeRangeCheck = true
					return
				}
			} else {
				let isEligible = try await AgeRangeService.shared.isEligibleForAgeFeatures
				guard isEligible else {
					hasCompletedAgeRangeCheck = true
					return
				}
			}

			let gates = AgeAssurancePolicy.ageGates
			_ = try await requestAgeRange(ageGates: gates.0, gates.1, gates.2)
			hasCompletedAgeRangeCheck = true
		} catch {
			// Leave the check incomplete so a temporary failure retries when the app next becomes active.
		}
	}
}
#else
@available(iOS 26.2, *)
private struct DeclaredAgeRangeComplianceTask: View {
	var body: some View {
		EmptyView()
	}
}
#endif
