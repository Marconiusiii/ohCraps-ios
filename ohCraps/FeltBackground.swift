import SwiftUI

struct FeltBackground: View {
	var body: some View {
		ZStack {
			AppTheme.feltGradient
			AppTheme.feltNoise
				.blendMode(.overlay)
		}
		.ignoresSafeArea()
	}
}
