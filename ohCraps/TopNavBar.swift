import SwiftUI

struct TopNavBar: View {
	let title: String
	let showBack: Bool
	let backAction: () -> Void
	
	@AccessibilityFocusState private var isTitleFocused: Bool
	
	private var barColor: Color {
		// Craps-table style green; tweak if you like
		Color(red: 0.0, green: 0.35, blue: 0.18)
	}
	
	var body: some View {
		HStack {
			// BACK BUTTON
			if showBack {
				Button(action: backAction) {
					Text("Back")
						.font(.headline)
						.minimumScaleFactor(0.8)
						.lineLimit(1)
				}
				.accessibilityLabel("Back")
				.accessibilityHint("Returns to the previous screen")
			}
			
			Spacer()
			
			// TITLE
			Text(title)
				.font(.largeTitle.bold())
				.multilineTextAlignment(.center)
				.lineLimit(2)
				.minimumScaleFactor(0.75)
				.accessibilityAddTraits(.isHeader)
				.accessibilityFocused($isTitleFocused)
			
			Spacer()
			
			// BALANCING SPACER
			if showBack {
				Color.clear.frame(width: 50)
			}
		}
		.padding(.horizontal)
		.padding(.vertical, 12)
		.background(barColor)
		.onAppear {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
				isTitleFocused = true
			}
		}
	}
}
