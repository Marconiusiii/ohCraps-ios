import SwiftUI

struct FeltBackground: View {
	var body: some View {
		ZStack {
			AppTheme.feltGradient
				.ignoresSafeArea()

			RadialGradient(
				colors: [
					Color.black.opacity(0.0),
					Color.black.opacity(0.30)
				],
				center: .center,
				startRadius: 200,
				endRadius: 600
			)
			.ignoresSafeArea()
			.allowsHitTesting(false)

			AppTheme.feltNoise
				.blendMode(.overlay)
				.ignoresSafeArea()
				.allowsHitTesting(false)
		}
	}
}
