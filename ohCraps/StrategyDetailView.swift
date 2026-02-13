import SwiftUI

struct StrategyDetailView: View {
	let strategy: Strategy
	@Environment(\.dismiss) private var dismiss
	let userStrategy: UserStrategy?
	let edit: (() -> Void)?
	let duplicate: (() -> Void)?
	let submit: (() -> Void)?
	let delete: (() -> Void)?

	init(
		strategy: Strategy,
		userStrategy: UserStrategy? = nil,
		edit: (() -> Void)? = nil,
		duplicate: (() -> Void)? = nil,
		submit: (() -> Void)? = nil,
		delete: (() -> Void)? = nil
	) {
		self.strategy = strategy
		self.userStrategy = userStrategy
		self.edit = edit
		self.duplicate = duplicate
		self.submit = submit
		self.delete = delete
	}

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
		ZStack {
			FeltBackground()
			VStack(spacing: 0) {
				
				// Custom header with Back button and dynamic, centered title
				TopNavBar(
					title: strategy.name,
					showBack: true,
					backAction: { dismiss() }
				)
				if let userStrategy = userStrategy {
					Menu("Strategy Actions") {
						Button("Edit") {
							edit?()
						}

						Button("Duplicate") {
							duplicate?()
						}

						Button(userStrategy.isSubmitted ? "Resubmit" : "Submit") {
							submit?()
						}

						Button("Delete \(userStrategy.name)", role: .destructive) {
							delete?()
						}
					}
					.font(AppTheme.cardTitle)
					.padding(.vertical, 8)
					.accessibilityLabel("Strategy Actions")
				}

				ScrollView {
					VStack(alignment: .leading, spacing: 24) {
						
						// BUY-IN AND TABLE MINIMUM
						DetailKVGroup(label: "Buy-in", value: strategy.buyInText)
						DetailKVGroup(label: "Table Minimum", value: strategy.tableMinText)
						
						// NOTES
						if !strategy.notes.isEmpty {
							VStack(alignment: .leading, spacing: 8) {
								Text("Notes")
									.font(AppTheme.sectionHeader)
									.accessibilityAddTraits(.isHeader)
								
								Text(strategy.notes)
									.font(AppTheme.bodyText)
									.fixedSize(horizontal: false, vertical: true)
							}
						}
						// Credits
						if !strategy.credit.isEmpty {
							VStack(alignment: .leading, spacing: 8) {
								Text("Credits")
									.font(AppTheme.sectionHeader)
									.accessibilityAddTraits(.isHeader)
								
								Text(strategy.credit)
									.font(AppTheme.bodyText)
									.fixedSize(horizontal: false, vertical: true)
							}
						}

						
						// STEPS
						if !renderedLines.isEmpty {
							VStack(alignment: .leading, spacing: 12) {
								Text("Steps")
									.font(AppTheme.sectionHeader)
									.accessibilityAddTraits(.isHeader)
								
								ForEach(renderedLines) { line in
									switch line.kind {
									case .heading:
										Text(line.text)
											.font(AppTheme.sectionHeader)
											.padding(.top, 6)
											.accessibilityAddTraits(.isHeader)
											.fixedSize(horizontal: false, vertical: true)
										
									case .step(let number):
										Text("\(number). \(line.text)")
											.font(AppTheme.bodyText)
											.fixedSize(horizontal: false, vertical: true)
										
									case .bullet:
										HStack(alignment: .top, spacing: 8) {
											Text("•")
												.font(AppTheme.bodyText)
											Text(line.text)
												.font(AppTheme.bodyText)
												.fixedSize(horizontal: false, vertical: true)
											
										}
										.accessibilityElement(children: .combine)
										.padding(.leading, 16)
										
									case .paragraph:
										Text(line.text)
											.font(AppTheme.secondaryText)
											.fixedSize(horizontal: false, vertical: true)
									}
								}
							}
						}
					}
					.padding()
				}
			}
			.navigationBarBackButtonHidden(true)
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
				.font(AppTheme.cardTitle)
			Spacer(minLength: 8)
			Text(value)
				.font(AppTheme.bodyText)
		}
		.accessibilityElement(children: .combine)
		.accessibilityLabel("\(label): \(value)")
	}
}
