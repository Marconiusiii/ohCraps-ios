import SwiftUI

struct AppTheme {

	// MARK: - Typography

	static let screenTitle = Font.title3.weight(.semibold)

	static let sectionHeader = Font.title3.weight(.bold)

	static let cardTitle = Font.headline

	static let bodyText = Font.body

	static let secondaryText = Font.subheadline

	static let metadataText = Font.caption

	// MARK: - Tab Bar

	static let tabBarHighlight = Color.white.opacity(0.08)

	static let tabBarBackground = Color(
		red: 0.18,
		green: 0.10,
		blue: 0.06
	)
//Tob Bar Background
	static let topBarBackground = Color(red: 0.0, green: 0.35, blue: 0.18)

	
	static let tabBarBorder = Color.white.opacity(0.25)

	static let tabTextActive = Color.white

	static let tabTextInactive = Color.white.opacity(0.7)

	// MARK: - Colors
	
	static let feltTop = Color(red: 0.15, green: 0.47, blue: 0.08)
	static let feltBottom = Color(red: 0.12, green: 0.36, blue: 0.06)
	static let feltNoise = Color.white.opacity(0.03)

	
	static let panelBackground = Color.black.opacity(0)
	static let cardBackground = Color.black.opacity(0)
	
	static let textPrimary = Color.white
	static let headingGold = Color(red: 1.0, green: 0.84, blue: 0.0)
	static let borderColor = Color.white.opacity(0.75)
	
	// MARK: - Gradients
	
	static let feltGradient = LinearGradient(
		colors: [feltTop, feltBottom],
		startPoint: .top,
		endPoint: .bottom
	)
	
	// MARK: - Components
	
	static func menuLabel(text: String, value: String) -> some View {
		HStack(spacing: 4) {
			Text("\(text): \(value)")
				.foregroundColor(textPrimary)
			Image(systemName: "chevron.down")
				.foregroundColor(textPrimary)
		}
		.padding(8)
		.background(cardBackground)
		.overlay(
			RoundedRectangle(cornerRadius: 8)
				.stroke(borderColor, lineWidth: 1)
		)
		.cornerRadius(8)
	}
	
	static func panel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
		VStack(spacing: 12) {
			content()
		}
		.padding()
		.background(panelBackground)
		.cornerRadius(20)
	}
	
	// MARK: - Rail (Craps Table Wood)

	static let railWoodDark = Color(red: 0.16, green: 0.08, blue: 0.04)
	static let railWoodMid = Color(red: 0.22, green: 0.12, blue: 0.06)
	static let railWoodLight = Color(red: 0.30, green: 0.18, blue: 0.10)

	static let railGradient = LinearGradient(
		colors: [
			railWoodLight,
			railWoodMid,
			railWoodDark
		],
		startPoint: .top,
		endPoint: .bottom
	)

	
}
