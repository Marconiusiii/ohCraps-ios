import SwiftUI

struct RootView: View {
		@State private var selectedTab: AppTab = .strategies

	var body: some View {
		VStack(spacing: 0) {

			// CONTENT
			switch selectedTab {
			case .strategies:
				StrategiesView()

			case .rules:
				RulesView()
			case .createStrategy:
				CreateStrategyView()
			case .about:
				AboutView()
			}

			// CUSTOM TAB BAR
			CustomTabBar(selectedTab: $selectedTab)
		}
		.dynamicTypeSize(.xSmall ... .accessibility5)
	}
}

