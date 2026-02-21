import SwiftUI

enum DetailFocusTarget {
	case title
	case actions
}

struct StrategyDetailView: View {
	@Binding var hideTabBar: Bool
	@Binding var keepBarHiddenOnClose: Bool
	let strategy: Strategy
	@Environment(\.dismiss) private var dismiss
	let userStrategy: UserStrategy?
	let edit: (() -> Void)?
	let duplicate: (() -> Void)?
	let submit: (() -> Void)?
	let delete: (() -> Void)?
	let onShow: (() -> Void)?
	let onGone: (() -> Void)?
	let initialAccessibilityFocus: DetailFocusTarget
	let focusRevision: Int
	@AccessibilityFocusState private var titleFocused: Bool
	@AccessibilityFocusState private var actionsFocused: Bool
	@AccessibilityFocusState private var coreShareFocused: Bool
	@State private var sharePayload: SharePayload?
	@State private var showDetailSubmitAlert = false
	@State private var showDetailDeleteAlert = false

	init(
		strategy: Strategy,
		hideTabBar: Binding<Bool> = .constant(false),
		keepBarHiddenOnClose: Binding<Bool> = .constant(false),
		userStrategy: UserStrategy? = nil,
		edit: (() -> Void)? = nil,
		duplicate: (() -> Void)? = nil,
		submit: (() -> Void)? = nil,
		delete: (() -> Void)? = nil,
		onShow: (() -> Void)? = nil,
		onGone: (() -> Void)? = nil,
		initialAccessibilityFocus: DetailFocusTarget = .title,
		focusRevision: Int = 0
	) {
		self._hideTabBar = hideTabBar
		self._keepBarHiddenOnClose = keepBarHiddenOnClose
		self.strategy = strategy
		self.userStrategy = userStrategy
		self.edit = edit
		self.duplicate = duplicate
		self.submit = submit
		self.delete = delete
		self.onShow = onShow
		self.onGone = onGone
		self.initialAccessibilityFocus = initialAccessibilityFocus
		self.focusRevision = focusRevision
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
				.accessibilityFocused($titleFocused)
				if let userStrategy = userStrategy {
					Menu("Strategy Actions") {
						Button("Edit") {
							edit?()
						}

						Button("Duplicate") {
							duplicate?()
						}

						Button(userStrategy.isSubmitted ? "Resubmit" : "Submit") {
							showDetailSubmitAlert = true
						}

						Button("Share Strategy") {
							sharePayload = SharePayload(
								strategyName: userStrategy.name,
								text: StrategyShareFormatter.shareText(for: userStrategy)
							)
						}

						Button("Delete \(userStrategy.name)", role: .destructive) {
							showDetailDeleteAlert = true
						}
					}
					.font(AppTheme.cardTitle)
					.padding(.vertical, 8)
					.accessibilityLabel("Strategy Actions")
					.accessibilityFocused($actionsFocused)

					Text(submissionStatusText(for: userStrategy))
						.font(AppTheme.bodyText)
						.padding(.horizontal)
				} else {
					Button("Share Strategy") {
						sharePayload = SharePayload(
							strategyName: strategy.name,
							text: StrategyShareFormatter.shareText(for: strategy)
						)
					}
					.font(AppTheme.cardTitle)
					.padding(.vertical, 8)
					.accessibilityFocused($coreShareFocused)
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
		.onAppear {
			hideTabBar = true
			onShow?()
			applyAccessibilityFocus(initialAccessibilityFocus)
		}
		.onDisappear {
			hideTabBar = keepBarHiddenOnClose
			keepBarHiddenOnClose = false
			onGone?()
		}
		.onChange(of: focusRevision) { _ in
			applyAccessibilityFocus(initialAccessibilityFocus)
		}
		.sheet(item: $sharePayload, onDismiss: {
			if userStrategy != nil {
				applyAccessibilityFocus(.actions)
			} else {
				DispatchQueue.main.async {
					coreShareFocused = true
				}
			}
		}) { payload in
			ShareSheet(payload: payload)
		}
		.alert(
			"Submit \(userStrategy?.name ?? "") to Oh Craps?",
			isPresented: $showDetailSubmitAlert
		) {
			Button("Yes, Submit") {
				submit?()
			}
			Button("Cancel", role: .cancel) {
				applyAccessibilityFocus(.actions)
			}
		} message: {
			Text("Submit your strategy so it will appear for all Oh Craps! users. It will be added in the next app update.")
		}
		.alert(
			"Delete \(userStrategy?.name ?? "Strategy")?",
			isPresented: $showDetailDeleteAlert
		) {
			Button("Delete", role: .destructive) {
				delete?()
			}
			Button("Cancel", role: .cancel) {
				applyAccessibilityFocus(.actions)
			}
		}
	}

	private func submissionStatusText(for strategy: UserStrategy) -> String {
		if strategy.isSubmitted {
			return "Strategy Submitted to Oh Craps!"
		}
		if strategy.hasBeenSubmitted, strategy.dateLastEdited != nil {
			return "Ready to resubmit."
		}
		return "Ready to submit."
	}

	private func applyAccessibilityFocus(_ target: DetailFocusTarget) {
		DispatchQueue.main.async {
			switch target {
			case .title:
				titleFocused = true
				actionsFocused = false
			case .actions:
				actionsFocused = true
				titleFocused = false
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
				.font(AppTheme.cardTitle)
			Spacer(minLength: 8)
			Text(value)
				.font(AppTheme.bodyText)
		}
		.accessibilityElement(children: .combine)
		.accessibilityLabel("\(label): \(value)")
	}
}
