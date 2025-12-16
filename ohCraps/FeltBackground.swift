import SwiftUI

struct FeltBackground: View {
	var body: some View {
		ZStack {
			// Base felt color (deterministic)
			Color(red: 0.10, green: 0.32, blue: 0.14)
				.ignoresSafeArea()

			// Subtle vignette to sell depth
			RadialGradient(
				colors: [
					Color.black.opacity(0.0),
					Color.black.opacity(0.35)
				],
				center: .center,
				startRadius: 200,
				endRadius: 600
			)
			.ignoresSafeArea()
			.allowsHitTesting(false)
		}
	}
}
