import SwiftUI

struct TopNavBar: View {
	let title: String
	let showBack: Bool
	let backAction: () -> Void

	var body: some View {
		HStack(alignment: .center, spacing: 8) {

			if showBack {
				Button(action: backAction) {
					Text("Back")
						.font(AppTheme.cardTitle)
				}
				.foregroundColor(AppTheme.textPrimary)
				.accessibilityLabel("Back")
			}

			Spacer(minLength: 8)

			Text(title)
				.font(AppTheme.screenTitle)
				.multilineTextAlignment(.center)
				.lineLimit(
			2)
				.minimumScaleFactor(0.75)
				.accessibilityAddTraits(.isHeader)
			Spacer(minLength: 8)

			// BALANCER — preserves visual centering when Back exists
			if showBack {
				Color.clear
					.frame(width: 44)
					.accessibilityHidden(true)
			}
		}
		.padding(.horizontal)
		.padding(.vertical, 6)
		.background(AppTheme.topBarBackground)
		.accessibilityElement(children: .contain)
	}
}

