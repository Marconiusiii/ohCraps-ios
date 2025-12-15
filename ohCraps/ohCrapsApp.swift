import SwiftUI

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
		}
	}
}

