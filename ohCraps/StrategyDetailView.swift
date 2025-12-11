import SwiftUI

struct StrategyDetailView: View {
	let strategy: Strategy
	@Environment(\.dismiss) private var dismiss
	
	private struct RenderLine: Identifiable {
		enum Kind {
			case heading        // from <h4>
			case step(number: Int)
			case bullet
			case paragraph
		}
		
		let id = UUID()
		let kind: Kind
		let text: String
	}
	
	// Interpret the tagged step strings from Strategy.steps
	private var renderedLines: [RenderLine] {
		var lines: [RenderLine] = []
		var stepIndex = 1
		
		for raw in strategy.steps {
			let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
			if trimmed.isEmpty { continue }
			
			if trimmed.hasPrefix("§H4§") {
				let text = trimmed
					.replacingOccurrences(of: "§H4§", with: "")
					.trimmingCharacters(in: .whitespacesAndNewlines)
				guard !text.isEmpty else { continue }
				
				lines.append(
					RenderLine(kind: .heading, text: text)
				)
				// Reset numbering after a subheading
				stepIndex = 1
				
			} else if trimmed.hasPrefix("§STEP§") {
				let text = trimmed
					.replacingOccurrences(of: "§STEP§", with: "")
					.trimmingCharacters(in: .whitespacesAndNewlines)
				guard !text.isEmpty else { continue }
				
				lines.append(
					RenderLine(kind: .step(number: stepIndex), text: text)
				)
				stepIndex += 1
				
			} else if trimmed.hasPrefix("§BULLET§") {
				let text = trimmed
					.replacingOccurrences(of: "§BULLET§", with: "")
					.trimmingCharacters(in: .whitespacesAndNewlines)
				guard !text.isEmpty else { continue }
				
				lines.append(
					RenderLine(kind: .bullet, text: text)
				)
				
			} else if trimmed.hasPrefix("§PARA§") {
				let text = trimmed
					.replacingOccurrences(of: "§PARA§", with: "")
					.trimmingCharacters(in: .whitespacesAndNewlines)
				guard !text.isEmpty else { continue }
				
				lines.append(
					RenderLine(kind: .paragraph, text: text)
				)
				
			} else {
				// Fallback: treat untagged text as a paragraph
				lines.append(
					RenderLine(kind: .paragraph, text: trimmed)
				)
			}
		}
		
		return lines
	}
	
	var body: some View {
		VStack(spacing: 0) {
			
			// Custom header with Back button and dynamic, centered title
			TopNavBar(
				title: strategy.name,
				showBack: true,
				backAction: { dismiss() }
			)
			
			ScrollView {
				VStack(alignment: .leading, spacing: 24) {
					
					// BUY-IN AND TABLE MINIMUM
					DetailKVGroup(label: "Buy-in", value: strategy.buyInText)
					DetailKVGroup(label: "Table Minimum", value: strategy.tableMinText)
					
					// NOTES
					if !strategy.notes.isEmpty {
						VStack(alignment: .leading, spacing: 8) {
							Text("Notes")
								.font(.headline)
								.accessibilityAddTraits(.isHeader)
							
							Text(strategy.notes)
								.font(.body)
								.fixedSize(horizontal: false, vertical: true)
						}
					}
					
					// STEPS
					if !renderedLines.isEmpty {
						VStack(alignment: .leading, spacing: 12) {
							Text("Steps")
								.font(.headline)
								.accessibilityAddTraits(.isHeader)
							
							ForEach(renderedLines) { line in
								switch line.kind {
								case .heading:
									Text(line.text)
										.font(.headline)
										.padding(.top, 8)
										.accessibilityAddTraits(.isHeader)
										.fixedSize(horizontal: false, vertical: true)
									
								case .step(let number):
									Text("\(number). \(line.text)")
										.font(.body)
										.fixedSize(horizontal: false, vertical: true)
									
								case .bullet:
									HStack(alignment: .top, spacing: 8) {
										Text("•")
											.font(.body)
										Text(line.text)
											.font(.body)
											.fixedSize(horizontal: false, vertical: true)
									}
									.padding(.leading, 16)
									
								case .paragraph:
									Text(line.text)
										.font(.body)
										.fixedSize(horizontal: false, vertical: true)
								}
							}
						}
					}
				}
				.padding()
			}
		}
	}
}

// MARK: - Key/Value Group for Buy-in and Table Minimum

struct DetailKVGroup: View {
	let label: String
	let value: String
	
	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			Text(label + ":")
				.font(.headline)
			Spacer(minLength: 8)
			Text(value)
				.font(.body)
		}
		.accessibilityElement(children: .combine)
		.accessibilityLabel("\(label): \(value)")
	}
}
