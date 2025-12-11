import SwiftUI

struct StrategyDetailView: View {
	let strategy: Strategy
	
	private struct RenderLine: Identifiable {
		enum Kind {
			case heading
			case step(number: Int)
			case bullet
			case paragraph
		}
		
		let id = UUID()
		let kind: Kind
		let text: String
	}
	
	private var renderedLines: [RenderLine] {
		var lines: [RenderLine] = []
		var stepIndex = 1
		
		for raw in strategy.steps {
			let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
			if trimmed.isEmpty { continue }
			
			if trimmed.hasPrefix("§H4§") {
				let text = trimmed.replacingOccurrences(of: "§H4§", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
				guard !text.isEmpty else { continue }
				
				lines.append(RenderLine(kind: .heading, text: text))
				stepIndex = 1 // reset numbering after a subheading
				
			} else if trimmed.hasPrefix("§STEP§") {
				let text = trimmed.replacingOccurrences(of: "§STEP§", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
				guard !text.isEmpty else { continue }
				
				lines.append(RenderLine(kind: .step(number: stepIndex), text: text))
				stepIndex += 1
				
			} else if trimmed.hasPrefix("§BULLET§") {
				let text = trimmed.replacingOccurrences(of: "§BULLET§", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
				guard !text.isEmpty else { continue }
				
				lines.append(RenderLine(kind: .bullet, text: text))
				
			} else if trimmed.hasPrefix("§PARA§") {
				let text = trimmed.replacingOccurrences(of: "§PARA§", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
				guard !text.isEmpty else { continue }
				
				lines.append(RenderLine(kind: .paragraph, text: text))
				
			} else {
				// Fallback: treat untagged lines as paragraphs
				lines.append(RenderLine(kind: .paragraph, text: trimmed))
			}
		}
		
		return lines
	}
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 24) {
				
				KVGroup(label: "Buy-in", value: strategy.buyInText)
				KVGroup(label: "Table Minimum", value: strategy.tableMinText)
				
				if !strategy.notes.isEmpty {
					VStack(alignment: .leading, spacing: 8) {
						Text("Notes")
							.font(.title2)
							.bold()
							.accessibilityAddTraits(.isHeader)
						
						Text(strategy.notes)
							.font(.body)
							.fixedSize(horizontal: false, vertical: true)
					}
				}
				
				VStack(alignment: .leading, spacing: 12) {
					Text("Steps")
						.font(.title2)
						.bold()
						.accessibilityAddTraits(.isHeader)
					
					ForEach(renderedLines) { line in
						switch line.kind {
						case .heading:
							Text(line.text)
								.font(.title3)
								.bold()
								.padding(.top, 12)
								.accessibilityAddTraits(.isHeader)
							
						case .step(let number):
							Text("\(number). \(line.text)")
								.font(.body)
								.fixedSize(horizontal: false, vertical: true)
							
						case .bullet:
							Text("• \(line.text)")
								.font(.body)
								.padding(.leading, 24)
								.fixedSize(horizontal: false, vertical: true)
							
						case .paragraph:
							Text(line.text)
								.font(.body)
								.fixedSize(horizontal: false, vertical: true)
						}
					}
				}
			}
			.padding()
		}
		.navigationTitle(strategy.name)
		.navigationBarTitleDisplayMode(.inline)
	}
}

struct KVGroup: View {
	let label: String
	let value: String
	
	var body: some View {
		HStack {
			Text(label + ":")
				.font(.headline)
			Spacer()
			Text(value)
				.font(.body)
		}
		.accessibilityElement(children: .combine)
		.accessibilityLabel("\(label): \(value)")
	}
}
