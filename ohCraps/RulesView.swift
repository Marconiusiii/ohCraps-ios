import SwiftUI

struct RulesView: View {

	@State private var expandedSections: Set<UUID> = []

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 24) {
				ForEach(rulesContent) { section in
					rulesSectionView(section)
				}
			}
			.padding()
		}
	}

	private func rulesSectionView(_ section: RulesSection) -> some View {
		VStack(alignment: .leading, spacing: 12) {
			Button {
				toggle(section.id)
			} label: {
				Text(section.title)
					.font(.title3)
			}
			
			if expandedSections.contains(section.id) {
				ForEach(section.blocks.indices, id: \.self) { index in
					RulesBlockView(block: section.blocks[index])
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
				.frame(maxWidth: .infinity, alignment: .leading)

		case .bulletList(let items):
			VStack(alignment: .leading, spacing: 6) {
				ForEach(items.indices, id: \.self) { index in
					Text("• \(items[index])")
						.frame(maxWidth: .infinity, alignment: .leading)
				}
			}

		case .subSection(let title, let blocks):
			VStack(alignment: .leading, spacing: 8) {
				Text(title)
					.font(.headline)

				ForEach(blocks.indices, id: \.self) { index in
					RulesBlockView(block: blocks[index])
				}
			}
		}
	}
}


