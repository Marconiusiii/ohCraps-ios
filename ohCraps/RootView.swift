import SwiftUI

struct RootView: View {
	var body: some View {
		TabView {
			StrategiesView()
				.tabItem {
					Label("Strategies", systemImage: "list.bullet.rectangle")
				}
				.accessibilityIdentifier("strategiesTab")
			
			RulesView()
				.tabItem {
					Label("Rules", systemImage: "book")
				}
				.accessibilityIdentifier("rulesTab")
		}
	}
}

