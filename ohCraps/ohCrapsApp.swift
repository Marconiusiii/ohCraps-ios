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
		if #available(iOS 26.0, *) {
			DeclaredAgeRangeComplianceTask()
		}
	}
}

#if canImport(DeclaredAgeRange)
@available(iOS 26.0, *)
private struct DeclaredAgeRangeComplianceTask: View {
	@Environment(\.requestAgeRange) private var requestAgeRange
	@State private var hasCheckedAgeRange = false

	var body: some View {
		Color.clear
			.frame(width: 0, height: 0)
			.accessibilityHidden(true)
			.task {
				await checkDeclaredAgeRangeIfRequired()
			}
	}

	private func checkDeclaredAgeRangeIfRequired() async {
		guard !hasCheckedAgeRange else { return }
		hasCheckedAgeRange = true

		do {
			if #available(iOS 26.4, *) {
				let features = try await AgeRangeService.shared.requiredRegulatoryFeatures
				guard features.contains(.declaredAgeRangeRequired) else { return }
			} else if #available(iOS 26.2, *) {
				let isEligible = try await AgeRangeService.shared.isEligibleForAgeFeatures
				guard isEligible else { return }
			}

			_ = try await requestAgeRange(ageGates: 13, 16, 18)
		} catch {
			// Age range sharing is platform-managed and optional outside required regions.
		}
	}
}
#else
@available(iOS 26.0, *)
private struct DeclaredAgeRangeComplianceTask: View {
	var body: some View {
		EmptyView()
	}
}
#endif
