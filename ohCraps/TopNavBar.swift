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
				.lineLimit(2)
				.minimumScaleFactor(titleScale(for: title))
				.fixedSize(horizontal: false, vertical: true)
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
		.frame(minHeight: 44, maxHeight: 72)
		.background(AppTheme.topBarBackground)
		.accessibilityElement(children: .contain)
	}
	private func titleScale(for text: String) -> CGFloat {
		let count = text.count

		if count <= 20 {
			return 1.0
		} else if count <= 35 {
			return 0.9
		} else if count <= 55 {
			return 0.8
		} else {
			return 0.7
		}
	}
}

