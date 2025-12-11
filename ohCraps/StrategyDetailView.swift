import SwiftUI

struct StrategyDetailView: View {
	let strategy: Strategy
	
	private var renderedSteps: [String] {
		var result: [String] = []
		var stepIndex = 1
		
		for line in strategy.steps {
			let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
			
			if trimmed.hasPrefix("• ") {
				// Bullet line: keep as bullet, do not increment stepIndex
				result.append(trimmed)
			} else if trimmed.isEmpty {
				continue
			} else {
				// Top-level step: add numbering
				result.append("\(stepIndex). \(trimmed)")
				stepIndex += 1
			}
		}
		
		return result
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
					
					ForEach(renderedSteps.indices, id: \.self) { idx in
						let line = renderedSteps[idx]
						
						if line.hasPrefix("• ") {
							// Bullet item: indent a bit
							Text(line)
								.font(.body)
								.padding(.leading, 24)
								.fixedSize(horizontal: false, vertical: true)
						} else {
							// Numbered step
							Text(line)
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
