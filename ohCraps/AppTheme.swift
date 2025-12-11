import SwiftUI

struct AppTheme {
	
	// MARK: - Colors
	
	static let feltTop = Color(red: 0.15, green: 0.47, blue: 0.08)
	static let feltBottom = Color(red: 0.12, green: 0.36, blue: 0.06)
	
	static let panelBackground = Color.black.opacity(0.40)
	static let cardBackground = Color.black.opacity(0.80)
	
	static let textPrimary = Color.white
	static let headingGold = Color(red: 1.0, green: 0.84, blue: 0.0)
	static let borderColor = Color.white
	
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
}
