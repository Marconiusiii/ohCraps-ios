import SwiftUI

struct RootView: View {
		@State private var selectedTab: AppTab = .strategies
	@StateObject private var userStrategyStore = UserStrategyStore()
	@State private var hideTabBar = false

	var body: some View {
		VStack(spacing: 0) {

			// CONTENT
			switch selectedTab {
			case .strategies:
				StrategiesView()

			case .rules:
				RulesView()
			case .createStrategy:
				NavigationStack {
					CreateStrategyView(hideTabBar: $hideTabBar)
				}
				.environmentObject(userStrategyStore)
			case .about:
				AboutView()
			}

			// CUSTOM TAB BAR
			if !hideTabBar {
				CustomTabBar(selectedTab: $selectedTab)
			}
		}
		.dynamicTypeSize(.xSmall ... .accessibility5)
	}
}
