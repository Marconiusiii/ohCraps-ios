import SwiftUI

struct RootView: View {
	private let whatsNewVersion = "1.2.4"
	@State private var selectedTab: AppTab = .strategies
	@StateObject private var userStrategyStore = UserStrategyStore()
	@State private var hideTabBar = false
	@State private var showWhatsNew = false
	@AppStorage("whatsNewSeenVersion") private var seenWhatsNew = ""

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

				AboutView(showWhatsNew: $showWhatsNew)
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
		.sheet(isPresented: $showWhatsNew, onDismiss: markWhatsNewSeen) {
			WhatsNewView(
				version: whatsNewVersion,
				items: [
					"Added Strategies: B Squeeze, Build and Bail, We Ball",
					"App optimization and cleanup to make everything load faster."
				],
				onClose: { showWhatsNew = false }
			)
		}
		.task {
			showWhatsNewIfNeeded()
		}
	}

	private func showWhatsNewIfNeeded() {
		if seenWhatsNew != whatsNewVersion {
			showWhatsNew = true
		}
	}

	private func markWhatsNewSeen() {
		if seenWhatsNew != whatsNewVersion {
			seenWhatsNew = whatsNewVersion
		}
	}
}
