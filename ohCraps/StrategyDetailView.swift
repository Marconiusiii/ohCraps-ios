import SwiftUI

enum DetailFocusTarget {
	case title
	case actions
}

struct StrategyDetailView: View {
	private struct LineKey: Hashable {
		let id: UUID
		let sig: Int
	}

	private struct RenderLine {
		enum Kind {
			case heading        // from <h4>
			case step(number: Int)
			case bullet
			case paragraph
		}
		
		let kind: Kind
		let text: String
	}

	@Binding var hideTabBar: Bool
	@Binding var keepBarHiddenOnClose: Bool
	@Binding var justSubID: UserStrategy.ID?
	let strategy: Strategy
	@Environment(\.dismiss) private var dismiss
	let userStrategy: UserStrategy?
	let edit: (() -> Void)?
	let duplicate: (() -> Void)?
	let submit: (() -> Void)?
	let delete: (() -> Void)?
	let onShow: (() -> Void)?
	let onGone: (() -> Void)?
	let onWillDismiss: (() -> Void)?
	let onFavToggled: ((UUID) -> Void)?
	let initialAccessibilityFocus: DetailFocusTarget
	let focusRevision: Int
	@EnvironmentObject private var favStore: FavoritesStore
	@EnvironmentObject private var notesStore: StrategyNotesStore
	@AccessibilityFocusState private var detailFocus: DetailFocusField?

	private enum DetailFocusField: Hashable {
		case title
		case actions
		case share
		case favorite
	}
	@State private var sharePayload: SharePayload?
	@State private var showDetailSubmitAlert = false
	@State private var showDetailDeleteAlert = false
	@State private var personalNote = ""
	@State private var noteSaveWork: DispatchWorkItem?


	private static let lineLock = NSLock()
	private static var lineCache: [LineKey: [RenderLine]] = [:]

	init(
		strategy: Strategy,
		hideTabBar: Binding<Bool> = .constant(false),
		keepBarHiddenOnClose: Binding<Bool> = .constant(false),
		justSubID: Binding<UserStrategy.ID?> = .constant(nil),
		userStrategy: UserStrategy? = nil,
		edit: (() -> Void)? = nil,
		duplicate: (() -> Void)? = nil,
		submit: (() -> Void)? = nil,
		delete: (() -> Void)? = nil,
		onShow: (() -> Void)? = nil,
		onGone: (() -> Void)? = nil,
		onWillDismiss: (() -> Void)? = nil,
		onFavToggled: ((UUID) -> Void)? = nil,
		initialAccessibilityFocus: DetailFocusTarget = .title,
		focusRevision: Int = 0
	) {
		self._hideTabBar = hideTabBar
		self._keepBarHiddenOnClose = keepBarHiddenOnClose
		self._justSubID = justSubID
		self.strategy = strategy
		self.userStrategy = userStrategy
		self.edit = edit
		self.duplicate = duplicate
		self.submit = submit
		self.delete = delete
		self.onShow = onShow
		self.onGone = onGone
		self.onWillDismiss = onWillDismiss
		self.onFavToggled = onFavToggled
		self.initialAccessibilityFocus = initialAccessibilityFocus
		self.focusRevision = focusRevision
	}

	private var isFav: Bool {
		favStore.isFavorite(strategy.id)
	}

	// Interpret the tagged step strings from Strategy.steps
	private var renderedLines: [RenderLine] {
		let key = LineKey(id: strategy.id, sig: strategy.steps.hashValue)
		Self.lineLock.lock()
		if let cached = Self.lineCache[key] {
			Self.lineLock.unlock()
			return cached
		}
		Self.lineLock.unlock()

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
		
		Self.lineLock.lock()
		Self.lineCache[key] = lines
		Self.lineLock.unlock()
		return lines
	}
	
	var body: some View {
		ZStack {
			FeltBackground()
			VStack(spacing: 0) {
				
				HStack(alignment: .center, spacing: 8) {
					Button(action: { onWillDismiss?(); dismiss() }) {
						Text("Back")
							.font(AppTheme.cardTitle)
					}
					.foregroundColor(AppTheme.textPrimary)
					.accessibilityLabel("Back")

					Spacer(minLength: 8)

					Text(strategy.name)
						.font(AppTheme.screenTitle)
						.multilineTextAlignment(.center)
						.lineLimit(2)
						.minimumScaleFactor(titleScale(for: strategy.name))
						.fixedSize(horizontal: false, vertical: true)
						.accessibilityAddTraits(.isHeader)
						.accessibilityFocused($detailFocus, equals: .title)

					Spacer(minLength: 8)

					Color.clear
						.frame(width: 44)
						.accessibilityHidden(true)
				}
				.padding(.horizontal)
				.padding(.vertical, 6)
				.frame(minHeight: 44, maxHeight: 72)
				.background(AppTheme.topBarBackground)
				if let userStrategy = userStrategy {
					let isSub = userStrategy.isSubmitted || justSubID == userStrategy.id
					Menu("Strategy Actions") {
						Button("Edit") {
							dismiss()
							DispatchQueue.main.async {
								edit?()
							}
						}

						Button("Duplicate") {
							duplicate?()
						}

						Button(isSub ? "Resubmit" : "Submit") {
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
					.accessibilityFocused($detailFocus, equals: .actions)

					Text(submissionStatusText(for: userStrategy))
						.font(AppTheme.bodyText)
						.padding(.horizontal)
				} else {
					HStack(spacing: 12) {
						Button(action: { favStore.toggle(strategy.id); onFavToggled?(strategy.id) }) {
							HStack(spacing: 6) {
								Image(systemName: isFav ? "star.fill" : "star")
									.foregroundColor(isFav ? .yellow : AppTheme.textPrimary)
									.accessibilityHidden(true)
								Text("Favorite Strategy")
							}
						}
						.font(AppTheme.cardTitle)
						.foregroundColor(AppTheme.textPrimary)
						.padding(.horizontal, 12)
						.padding(.vertical, 8)
						.background(Color.black.opacity(0.4))
						.overlay(
							RoundedRectangle(cornerRadius: 8)
								.stroke(AppTheme.borderColor, lineWidth: 1)
						)
						.cornerRadius(8)
						.accessibilityLabel("Favorite Strategy")
						.accessibilityValue(isFav ? "On" : "Off")
						.accessibilityHint(isFav ? "Double-tap to unfavorite" : "Double-tap to favorite")
						.accessibilityFocused($detailFocus, equals: .favorite)

						Button("Share Strategy") {
							sharePayload = SharePayload(
								strategyName: strategy.name,
								text: StrategyShareFormatter.shareText(for: strategy)
							)
						}
						.font(AppTheme.cardTitle)
						.foregroundColor(AppTheme.textPrimary)
						.padding(.horizontal, 12)
						.padding(.vertical, 8)
						.background(Color.black.opacity(0.4))
						.overlay(
							RoundedRectangle(cornerRadius: 8)
								.stroke(AppTheme.borderColor, lineWidth: 1)
						)
						.cornerRadius(8)
						.accessibilityFocused($detailFocus, equals: .share)
					}
					.padding(.horizontal)
					.padding(.vertical, 8)
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
								
								ForEach(Array(renderedLines.enumerated()), id: \.offset) { _, line in
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
						// Personal Notes
						VStack(alignment: .leading, spacing: 8) {
							Text("Personal Notes")
								.font(AppTheme.sectionHeader)
								.accessibilityAddTraits(.isHeader)

							TextEditor(text: $personalNote)
								.frame(minHeight: 180)
								.padding(8)
								.background(Color.black.opacity(0.35))
								.overlay(
									RoundedRectangle(cornerRadius: 8)
										.stroke(AppTheme.borderColor, lineWidth: 1)
								)
								.cornerRadius(8)
								.font(AppTheme.bodyText)
								.foregroundColor(AppTheme.textPrimary)
								.accessibilityLabel("Personal Notes")

							Text("Your own notes for this strategy. These save automatically.")
								.font(AppTheme.metadataText)
								.foregroundColor(AppTheme.textPrimary)



						}
					}
					.padding()
				}
			}
			.navigationBarBackButtonHidden(true)
		}
		.accessibilityAction(.escape) {
			onWillDismiss?()
			dismiss()
		}
		.onAppear {
			hideTabBar = true
			onShow?()
			personalNote = notesStore.note(for: strategy.id)
			applyAccessibilityFocus(initialAccessibilityFocus)
		}
		.onDisappear {
			hideTabBar = keepBarHiddenOnClose
			keepBarHiddenOnClose = false
			onGone?()
			noteSaveWork?.cancel()
			notesStore.setNote(personalNote, for: strategy.id)
		}
		.onChange(of: focusRevision) {
			applyAccessibilityFocus(initialAccessibilityFocus)
		}
		.onChange(of: personalNote) { _, newValue in
			noteSaveWork?.cancel()

			let work = DispatchWorkItem {
				notesStore.setNote(newValue, for: strategy.id)
			}

			noteSaveWork = work
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
		}
.sheet(item: $sharePayload, onDismiss: {
			if userStrategy != nil {
				applyAccessibilityFocus(.actions)
			} else {
				Task { @MainActor in
					await Task.yield()
					detailFocus = .share
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
		.toolbar {
			ToolbarItemGroup(placement: .keyboard) {
				Spacer()
				Button("Dismiss Keyboard") {
					UIApplication.shared.sendAction(
						#selector(UIResponder.resignFirstResponder),
						to: nil,
						from: nil,
						for: nil
					)
				}
				.accessibilityLabel("Dismiss keyboard")
			}
		}

	}

	private func submissionStatusText(for strategy: UserStrategy) -> String {
		if strategy.isSubmitted || justSubID == strategy.id {
			return "Strategy Submitted to Oh Craps!"
		}
		if strategy.hasBeenSubmitted, strategy.dateLastEdited != nil {
			return "Ready to resubmit."
		}
		return "Ready to submit."
	}

	private func applyAccessibilityFocus(_ target: DetailFocusTarget) {
		Task { @MainActor in
			detailFocus = nil
			await Task.yield()
			await Task.yield()
			switch target {
			case .title: detailFocus = .title
			case .actions: detailFocus = .actions
			}
		}
	}

	private func titleScale(for text: String) -> CGFloat {
		let count = text.count

		if count <= 20 {
			return 1.0
		} else if count <= 35 {
			return 0.9
		} else if count <= 55 {
			return 0.8
		} else {
			return 0.7
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
