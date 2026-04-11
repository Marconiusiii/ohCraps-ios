import SwiftUI

struct WhatsNewView: View {
	let version: String
	let items: [String]
	let onClose: () -> Void

	var body: some View {
		NavigationStack {
			ZStack {
				AppTheme.feltGradient
					.ignoresSafeArea()

				VStack(alignment: .leading, spacing: 20) {
					Text("What's New in v.\(version)")
						.font(AppTheme.screenTitle)
						.foregroundColor(AppTheme.textPrimary)
						.accessibilityAddTraits(.isHeader)

					VStack(alignment: .leading, spacing: 16) {
						ForEach(items, id: \.self) { item in
							HStack(alignment: .top, spacing: 10) {
								Text("•")
									.font(AppTheme.bodyText)
									.foregroundColor(AppTheme.textPrimary)
									.accessibilityHidden(true)

								Text(item)
									.font(AppTheme.bodyText)
									.foregroundColor(AppTheme.textPrimary)
									.fixedSize(horizontal: false, vertical: true)
							}
						}
					}

					Spacer()

					Button("Close") {
						onClose()
					}
					.font(AppTheme.bodyText)
					.foregroundColor(AppTheme.textPrimary)
				}
				.padding()
			}
			.accessibilityAction(.escape) {
				onClose()
			}
		}
	}
}
