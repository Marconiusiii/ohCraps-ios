import SwiftUI

struct RootView: View {
	var body: some View {
		TabView {
			StrategiesView()
				.tabItem {
					Text("Strategies")
				}

			RulesView()
				.tabItem {
					Text("Rules")
				}
		}
		.toolbarBackground(AppTheme.tabBarBackground, for: .tabBar)
		.toolbarBackground(.visible, for: .tabBar)
	}
}

