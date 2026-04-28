import SwiftUI

struct AppTheme {

	// MARK: - Typography

	static let screenTitle = Font.system(.title3, design: .serif).weight(.semibold)
	static let sectionHeader = Font.title3.weight(.bold)
	static let cardTitle = Font.headline
	static let bodyText = Font.body
	static let secondaryText = Font.subheadline
	static let metadataText = Font.caption

	// MARK: - Felt

	static let feltTop = Color(red: 0.15, green: 0.47, blue: 0.08)
	static let feltBottom = Color(red: 0.12, green: 0.36, blue: 0.06)
	static let feltCenter = Color(red: 0.08, green: 0.27, blue: 0.12)
	static let feltShadow = Color.black.opacity(0.24)
	static let feltLine = Color.white.opacity(0.82)
	static let feltLineSoft = Color.white.opacity(0.35)
	static let feltGold = Color(red: 0.86, green: 0.73, blue: 0.38)
	static let feltGoldSoft = Color(red: 0.67, green: 0.54, blue: 0.20)
	static let feltRed = Color(red: 0.74, green: 0.16, blue: 0.12)
	static let feltBlackInk = Color.black.opacity(0.68)

	static let feltGradient = LinearGradient(
		colors: [feltTop, feltCenter, feltBottom],
		startPoint: .top,
		endPoint: .bottom
	)
	static let feltNoise = Color.white.opacity(0.03)
	
	// Top Bar Background stays in the felt family and uses printed-line trim.
	static let topBarBackground = LinearGradient(
		colors: [
			feltTop.opacity(0.94),
			feltCenter.opacity(0.96)
		],
		startPoint: .top,
		endPoint: .bottom
	)

	// MARK: - Rail (Custom Tab Bar)

	static let railWoodDark = Color(red: 0.16, green: 0.09, blue: 0.05)
	static let railWoodMid = Color(red: 0.22, green: 0.12, blue: 0.07)
	static let railWoodLight = Color(red: 0.30, green: 0.17, blue: 0.10)

	static let railGradient = LinearGradient(
		colors: [
			railWoodLight.opacity(1.0),
			railWoodMid.opacity(0.95),
			railWoodDark.opacity(1.0)
		],
		startPoint: .top,
		endPoint: .bottom
	)
	static let railBorder = Color.white.opacity(0.18)
	static let railHighlight = Color.white.opacity(0.20)

	
	
	static let tabTextActive = Color.white
	static let tabTextInactive = Color.white.opacity(0.70)

	static let railChipWell = Color.black.opacity(0.22)
	static let railChipWellSelected = Color.black.opacity(0.34)

	static let railChipWellBorder = Color.white.opacity(0.12)
	static let railChipWellBorderSelected = Color.white.opacity(0.22)

	// MARK: - Components

	static let textPrimary = Color.white
	static let textSecondary = feltGold
	static let placeholderText = Color.white.opacity(0.92)
	static let borderColor = feltGold
	static let controlFill = LinearGradient(
		colors: [
			feltCenter.opacity(0.92),
			feltBottom.opacity(0.96)
		],
		startPoint: .top,
		endPoint: .bottom
	)
	static let controlInset = feltBlackInk
	static let sectionBackplate = feltBlackInk.opacity(0.55)

	static func feltControl<Content: View>(
		redAccent: Bool = false,
		@ViewBuilder content: () -> Content
	) -> some View {
		content()
			.padding(.horizontal, 10)
			.padding(.vertical, 7)
			.background(
				RoundedRectangle(cornerRadius: 8, style: .continuous)
					.fill(controlFill)
			)
			.overlay(
				RoundedRectangle(cornerRadius: 8, style: .continuous)
					.stroke(redAccent ? feltRed : borderColor, lineWidth: 1)
			)
			.overlay(
				RoundedRectangle(cornerRadius: 8, style: .continuous)
					.stroke(feltLineSoft, lineWidth: 1)
					.padding(2)
			)
			.shadow(color: feltShadow, radius: 2, y: 1)
	}

	static func menuLabel(text: String, value: String) -> some View {
		feltControl {
			HStack(spacing: 6) {
				Text("\(text):")
					.font(bodyText.weight(.semibold))
					.foregroundColor(textSecondary)
				Text(value)
					.font(bodyText)
					.foregroundColor(textPrimary)
					.fixedSize(horizontal: false, vertical: true)
				Image(systemName: "chevron.down")
					.foregroundColor(textSecondary)
			}
		}
	}
}
