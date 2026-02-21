import SwiftUI

struct RootView: View {
	@State private var selectedTab: AppTab = .strategies
	@StateObject private var userStrategyStore = UserStrategyStore()
	@State private var hideTabBar = false

	var body: some View {
		VStack(spacing: 0) {
			ZStack {
				StrategiesView(hideTabBar: $hideTabBar)
					.opacity(selectedTab == .strategies ? 1 : 0)
					.allowsHitTesting(selectedTab == .strategies)
					.accessibilityHidden(selectedTab != .strategies)

				RulesView()
					.opacity(selectedTab == .rules ? 1 : 0)
					.allowsHitTesting(selectedTab == .rules)
					.accessibilityHidden(selectedTab != .rules)

				NavigationStack {
					CreateStrategyView(hideTabBar: $hideTabBar)
				}
				.environmentObject(userStrategyStore)
				.opacity(selectedTab == .createStrategy ? 1 : 0)
				.allowsHitTesting(selectedTab == .createStrategy)
				.accessibilityHidden(selectedTab != .createStrategy)

				AboutView()
					.opacity(selectedTab == .about ? 1 : 0)
					.allowsHitTesting(selectedTab == .about)
					.accessibilityHidden(selectedTab != .about)
			}

			// CUSTOM TAB BAR
			if !hideTabBar {
				CustomTabBar(selectedTab: $selectedTab)
			}
		}
		.dynamicTypeSize(.xSmall ... .accessibility5)
	}
}
