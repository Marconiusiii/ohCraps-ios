import SwiftUI

struct CustomTabBar: View {
	@Binding var selectedTab: AppTab
	
	var body: some View {
		HStack(spacing: 12) {
			ForEach(AppTab.allCases, id: \.self) { tab in
				tabButton(for: tab)
			}
		}
		.padding(.horizontal, 12)
		.padding(.top, 10)
		.padding(.bottom, 10)
		.background(railBackground)
		.overlay(railEdge, alignment: .top)
		.accessibilityElement(children: .contain)
		.accessibilityLabel("Main navigation")
	}
	
	private var railBackground: some View {
		RoundedRectangle(cornerRadius: 18, style: .continuous)
			.fill(AppTheme.railGradient)
			.overlay(
				RoundedRectangle(cornerRadius: 18, style: .continuous)
					.stroke(AppTheme.railBorder, lineWidth: 1)
			)
			.overlay(
				RoundedRectangle(cornerRadius: 18, style: .continuous)
					.stroke(Color.black.opacity(0.35), lineWidth: 2)
					.blur(radius: 2)
					.offset(y: 1)
					.mask(
						RoundedRectangle(cornerRadius: 18, style: .continuous)
					)
			)
			.shadow(color: Color.black.opacity(0.6), radius: 8, y: 4)
	}

	private var railEdge: some View {
		Rectangle()
			.fill(AppTheme.railHighlight)
			.frame(height: 1)
			.opacity(0.8)
	}
	
	private func tabButton(for tab: AppTab) -> some View {
		let isSelected = (selectedTab == tab)
		let index = AppTab.allCases.firstIndex(of: tab) ?? 0
		let count = AppTab.allCases.count
		return Button {
			selectedTab = tab
		} label: {
			Text(tab.title)
				.font(AppTheme.cardTitle)
				.foregroundColor(isSelected ? AppTheme.tabTextActive : AppTheme.tabTextInactive)
				.lineLimit(1)
				.minimumScaleFactor(0.85)
				.frame(maxWidth: .infinity)
				.padding(.vertical, 10)
				.background(
					RoundedRectangle(cornerRadius: 14, style: .continuous)
						.fill(
							LinearGradient(
								colors: [
									Color.black.opacity(isSelected ? 0.45 : 0.35),
									Color.black.opacity(isSelected ? 0.25 : 0.20)
								],
								startPoint: .top,
								endPoint: .bottom
							)
						)
						.overlay(
							RoundedRectangle(cornerRadius: 14, style: .continuous)
								.stroke(Color.white.opacity(0.18), lineWidth: 1)
								.offset(y: -1)
						)
						.overlay(
							RoundedRectangle(cornerRadius: 14, style: .continuous)
								.stroke(Color.black.opacity(0.5), lineWidth: 1)
								.offset(y: 1)
						)
				)
		}
		.buttonStyle(.plain)
		.accessibilityAddTraits(isSelected ? [.isSelected] : [])
		.accessibilityValue("Tab \(index + 1) of \(count)")	}
}
