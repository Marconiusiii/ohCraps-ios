import SwiftUI

struct RootView: View {
	@State private var selectedTab: AppTab = .strategies
	@StateObject private var userStrategyStore = UserStrategyStore()
	@StateObject private var favStore = FavoritesStore()
	@State private var hideTabBar = false
	@State private var showWhatsNew = false
	@AppStorage("whatsNewSeenVersion") private var seenWhatsNew = ""

	var body: some View {
		VStack(spacing: 0) {
			ZStack {
				StrategiesView(hideTabBar: $hideTabBar)
					.environmentObject(favStore)
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
				.environmentObject(favStore)
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
				items: WhatsNewData.items,
				onClose: { showWhatsNew = false }
			)
		}
		.task {
			showWhatsNewIfNeeded()
		}
	}

	private var appVer: String {
		Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
	}

	private func showWhatsNewIfNeeded() {
		if seenWhatsNew != appVer {
			showWhatsNew = true
		}
	}

	private func markWhatsNewSeen() {
		if seenWhatsNew != appVer {
			seenWhatsNew = appVer
		}
	}
}
