import SwiftUI

struct TopNavBar: View {
	let title: String
	let showBack: Bool
	let backAction: () -> Void

	private let sideSlotWidth: CGFloat = 88

	var body: some View {
		HStack(spacing: 12) {
			leadingSlot

			Text(title)
				.font(.title2.weight(.bold))
				.foregroundColor(AppTheme.textPrimary)
				.multilineTextAlignment(.center)
				.lineLimit(2)
				.minimumScaleFactor(0.85)
				.accessibilityAddTraits(.isHeader)
				.frame(maxWidth: .infinity)

			trailingSlot
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 12)
		.background(AppTheme.tabBarBackground)
	}
}

private extension TopNavBar {
	@ViewBuilder
	var leadingSlot: some View {
		if showBack {
			Button(action: backAction) {
				Text("Back")
					.font(.headline)
					.foregroundColor(AppTheme.textPrimary)
					.lineLimit(1)
					.minimumScaleFactor(0.9)
					.frame(width: sideSlotWidth, alignment: .leading)
			}
			.accessibilityLabel("Back")
		} else {
			Color.clear
				.frame(width: sideSlotWidth, height: 1)
				.accessibilityHidden(true)
		}
	}

	var trailingSlot: some View {
		Color.clear
			.frame(width: sideSlotWidth, height: 1)
			.accessibilityHidden(true)
	}
}

