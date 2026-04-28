import SwiftUI

struct RulesView: View {

	@AppStorage("rulesExpSec")
	private var expSecStore: String = ""

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
	}

	private func rulesSectionView(_ section: RulesSection) -> some View {
		let expDict = readExpDict()
		let isExp = expDict[section.title, default: false]

		return VStack(alignment: .leading, spacing: 16) {

			Button {
				toggleSec(section.title)
			} label: {
				AppTheme.feltControl {
					HStack {
						Text(section.title)
							.font(AppTheme.sectionHeader)
							.foregroundColor(AppTheme.textPrimary)
						Spacer()
						Text(isExp ? "−" : "+")
							.font(AppTheme.sectionHeader)
							.foregroundColor(AppTheme.textSecondary)
							.accessibilityHidden(true)
					}
					.padding(.vertical, 4)
				}
			}
			.accessibilityValue(isExp ? "Expanded" : "Collapsed")
			.accessibilityHint(
				isExp
				? "Double-tap to collapse"
				: "Double-tap to expand"
			)

			if isExp {
				VStack(alignment: .leading, spacing: 14) {
					ForEach(section.blocks.indices, id: \.self) { index in
						RulesBlockView(block: section.blocks[index])
					}
				}
			}
		}
	}

	private func toggleSec(_ title: String) {
		var expDict = readExpDict()
		expDict[title] = !(expDict[title] ?? false)
		writeExpDict(expDict)
	}

	private func readExpDict() -> [String: Bool] {
		var out: [String: Bool] = [:]

		let entries = expSecStore.split(separator: "|")
		for entry in entries {
			let parts = entry.split(separator: "=", maxSplits: 1)
			guard !parts.isEmpty else { continue }

			let key = String(parts[0])
			let val = (parts.count == 2 && parts[1] == "1")
			out[key] = val
		}

		return out
	}

	private func writeExpDict(_ dict: [String: Bool]) {
		expSecStore =
			dict
			.map { "\($0.key)=\($0.value ? "1" : "0")" }
			.sorted()
			.joined(separator: "|")
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
