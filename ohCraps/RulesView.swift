import SwiftUI

struct RulesView: View {
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(alignment: .leading, spacing: 16) {
					Text("Rules of Craps")
						.font(.largeTitle)
						.bold()
					
					Text("Basic Overview")
						.font(.title2)
						.bold()
					
					Text("""
					Here you can describe the flow of a Craps game, including the come-out roll, point numbers, and basic bets like Pass Line and Don't Pass.

					We can later break this into multiple sections with more headings for different bet types and examples.
					""")
					
					Text("Key Terms")
						.font(.title2)
						.bold()
					
					Text("""
					Explain key terms such as Shooter, Point, Come Out, Seven Out, and so on.
					""")
				}
				.padding()
			}
			.background(AppTheme.feltGradient
.ignoresSafeArea())
			.navigationTitle("Rules")
			.navigationBarTitleDisplayMode(.inline)
		}
	}
}
