import SwiftUI

struct RulesView: View {

	@State private var expandedSections: Set<UUID> = []
	@AccessibilityFocusState private var titleFocused: Bool

	var body: some View {
		ZStack {
			AppTheme.feltGradient
				.ignoresSafeArea()

			VStack(alignment: .leading, spacing: 16) {

				TopNavBar(
					title: "Rules",
					showBack: false,
					backAction: {}
				)
				.accessibilityFocused($titleFocused)

				ScrollView {
					VStack(alignment: .leading, spacing: 28) {
						ForEach(rulesContent) { section in
							rulesSectionView(section)
						}
					}
					.padding(.horizontal)
					.padding(.bottom, 24)
				}
			}
		}
		.onAppear {
			// Defer focus until after the tab transition completes
			DispatchQueue.main.async {
				titleFocused = true
			}
		}
	}

	private func rulesSectionView(_ section: RulesSection) -> some View {
		VStack(alignment: .leading, spacing: 16) {

			Button {
				toggle(section.id)
			} label: {
				Text(section.title)
					.font(AppTheme.sectionHeader)
					.foregroundColor(AppTheme.textPrimary)
					.padding(.vertical, 12)
					.padding(.horizontal, 14)
					.background(Color.black.opacity(0.4))
					.cornerRadius(8)
			}
			.accessibilityValue(
				expandedSections.contains(section.id)
				? "Expanded"
				: "Collapsed"
			)
			.accessibilityHint(
				expandedSections.contains(section.id)
				? "Double-tap to collapse"
				: "Double-tap to expand"
			)

			if expandedSections.contains(section.id) {
				VStack(alignment: .leading, spacing: 14) {
					ForEach(section.blocks.indices, id: \.self) { index in
						RulesBlockView(block: section.blocks[index])
					}
				}
			}
		}
	}

	private func toggle(_ id: UUID) {
		if expandedSections.contains(id) {
			expandedSections.remove(id)
		} else {
			expandedSections.insert(id)
		}
	}
}

private struct RulesBlockView: View {

	let block: RulesBlock

	var body: some View {
		switch block {

		case .paragraph(let text):
			Text(text)
				.font(AppTheme.bodyText)
				.foregroundColor(AppTheme.textPrimary)
				.frame(maxWidth: .infinity, alignment: .leading)

		case .bulletList(let items):
			VStack(alignment: .leading, spacing: 8) {
				ForEach(items.indices, id: \.self) { index in
					Text("• \(items[index])")
						.font(AppTheme.bodyText)
						.foregroundColor(AppTheme.textPrimary)
						.frame(maxWidth: .infinity, alignment: .leading)
				}
			}

		case .subSection(let title, let blocks):
			VStack(alignment: .leading, spacing: 8) {
				Text(title)
					.font(AppTheme.cardTitle)
					.foregroundColor(AppTheme.textPrimary)
					.accessibilityAddTraits(.isHeader)

				ForEach(blocks.indices, id: \.self) { index in
					RulesBlockView(block: blocks[index])
				}
			}
		}
	}
}

