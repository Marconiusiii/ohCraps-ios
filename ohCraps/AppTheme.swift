import SwiftUI

struct AppTheme {

	// MARK: - Typography

	static let screenTitle = Font.title3.weight(.semibold)
	static let sectionHeader = Font.title3.weight(.bold)
	static let cardTitle = Font.headline
	static let bodyText = Font.body
	static let secondaryText = Font.subheadline
	static let metadataText = Font.caption

	// MARK: - Felt

	static let feltTop = Color(red: 0.15, green: 0.47, blue: 0.08)
	static let feltBottom = Color(red: 0.12, green: 0.36, blue: 0.06)

	static let feltGradient = LinearGradient(
		colors: [feltTop, feltBottom],
		startPoint: .top,
		endPoint: .bottom
	)
	static let feltNoise = Color.white.opacity(0.03)
	
//Tob Bar Background
	static let topBarBackground = Color(red: 0.0, green: 0.35, blue: 0.18)

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
	static let borderColor = Color.white.opacity(0.75)

	static func menuLabel(text: String, value: String) -> some View {
		HStack(spacing: 4) {
			Text("\(text): \(value)")
				.foregroundColor(textPrimary)
			Image(systemName: "chevron.down")
				.foregroundColor(textPrimary)
		}
		.padding(8)
		.background(Color.black.opacity(0.4))
		.overlay(
			RoundedRectangle(cornerRadius: 8)
				.stroke(borderColor, lineWidth: 1)
		)
		.cornerRadius(8)
	}
}

