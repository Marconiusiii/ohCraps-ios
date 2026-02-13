import SwiftUI
import UIKit
import MessageUI

struct CreateStrategyView: View {

	enum Mode: Int, CaseIterable {
		case create
		case myStrategies
	}

	private enum Field: Hashable {
		case name
		case buyIn
		case tableMin
		case steps
		case notes
		case credit
	}

	private enum ValidationError: Identifiable {
		case missingName
		case missingBuyIn
		case missingTableMinimum
		case missingSteps

		var id: Self { self }

		var message: String {
			switch self {
			case .missingName:
				return "Please enter a strategy name."
			case .missingBuyIn:
				return "Please enter a buy-in amount."
			case .missingTableMinimum:
				return "Please enter a table minimum."
			case .missingSteps:
				return "Please enter at least one step for the strategy."
			}
		}

		var field: Field {
			switch self {
			case .missingName: return .name
			case .missingBuyIn: return .buyIn
			case .missingTableMinimum: return .tableMin
			case .missingSteps: return .steps
			}
		}
	}

	private enum EditOrigin {
		case myStrategies
		case detail(UserStrategy.ID)
	}

	@EnvironmentObject private var store: UserStrategyStore

	@State private var mode: Mode = .create
	@State private var isEditing = false
	@State private var editingStrategyID: UserStrategy.ID?
	@State private var editOrigin: EditOrigin?
	@State private var editingOriginalStrategy: UserStrategy?

	@State private var strategyName = ""
	@State private var buyIn = ""
	@State private var tableMinimum = ""
	@State private var stepsText = ""
	@State private var notesText = ""
	@State private var credit = ""

	@State private var errorField: Field?
	@State private var validationError: ValidationError?
	@State private var validationErrors: [ValidationError] = []
	@State private var showValidationAlert = false

	@State private var longPressStrategy: UserStrategy?
	@State private var showStrategyActions = false

	@State private var submittingStrategy: UserStrategy?
	@State private var showSubmitAlert = false
	@State private var showMailComposer = false
	@State private var deleteCandidate: UserStrategy?
	@State private var showDeleteAlert = false
	@State private var showDiscardAlert = false

	@State private var selectedStrategy: Strategy?
	@State private var lastOpenedStrategyID: UserStrategy.ID?

	@FocusState private var focusField: Field?
	@AccessibilityFocusState private var focusedUserStrategyID: UserStrategy.ID?
	@AccessibilityFocusState private var titleFocused: Bool
	private var strategyActionsTitle: String {
		if let strategy = longPressStrategy {
			let submitLabel = strategy.isSubmitted ? "Resubmit" : "Submit"

			return "\(strategy.name) Actions"
		}
		return "Strategy Actions"
	}

	var body: some View {
		ZStack {
			FeltBackground()

			VStack(spacing: 0) {

				TopNavBar(
					title: "Create Strategy",
					showBack: false,
					backAction: {}
				)
				.accessibilityFocused($titleFocused)

				if !isEditing {
					Picker("Mode", selection: $mode) {
						Text("Create Strategy").tag(Mode.create)
						Text("My Strategies").tag(Mode.myStrategies)
					}
					.pickerStyle(.segmented)
					.padding()
				}

				ScrollView {
					switch mode {
					case .create:
						createForm
					case .myStrategies:
						myStrategiesList
					}
				}
			}
		}
		.onAppear { focusTitle() }

		.navigationDestination(item: $selectedStrategy) { strategy in
			let userStrategy = store.strategies.first(where: { $0.id == strategy.id })
			StrategyDetailView(
				strategy: strategy,
				userStrategy: userStrategy,
				edit: {
					if let userStrategy = userStrategy {
						editOrigin = .detail(userStrategy.id)
						beginEditing(userStrategy)
						selectedStrategy = nil
					}
				},
				duplicate: {
					if let userStrategy = userStrategy {
						duplicateStrategy(userStrategy)
					}
				},
				submit: {
					if let userStrategy = userStrategy {
						beginSubmit(userStrategy)
						selectedStrategy = nil
					}
				},
				delete: {
					if let userStrategy = userStrategy {
						beginDelete(userStrategy)
						selectedStrategy = nil
					}
				}
			)
		}

		.confirmationDialog(
			strategyActionsTitle,
			isPresented: $showStrategyActions,
			titleVisibility: .visible
		) {
			if let strategy = longPressStrategy {
				Button("Edit") {
					beginEditing(strategy)
				}

				Button("Duplicate") {
					duplicateStrategy(strategy)
				}

				Button(strategy.isSubmitted ? "Resubmit" : "Submit") {
					beginSubmit(strategy)
				}

				Button("Delete \(strategy.name)", role: .destructive) {
					beginDelete(strategy)
				}

				Button("Dismiss") {
					focusedUserStrategyID = strategy.id
					longPressStrategy = nil
					showStrategyActions = false
				}
			}
		}
		.onChange(of: showStrategyActions) { isPresented in
			if !isPresented {
				focusedUserStrategyID = longPressStrategy?.id
			}
		}

		.alert(
			"Submit \(submittingStrategy?.name ?? "") to Oh Craps?",
			isPresented: $showSubmitAlert
		) {
			Button("Yes, Submit") {
				showSubmitAlert = false
				showMailComposer = true
			}
			Button("Cancel", role: .cancel) {
				submittingStrategy = nil
			}
		} message: {
			Text("Submit your strategy so it will appear for all Oh Craps! users. It will be added in the next app update.")
		}
		.alert(
			"Delete \(deleteCandidate?.name ?? "Strategy")?",
			isPresented: $showDeleteAlert
		) {
			Button("Delete", role: .destructive) {
				if let strategy = deleteCandidate {
					store.delete(strategy)
				}
				deleteCandidate = nil
			}
		}
		.onChange(of: showDeleteAlert) { isPresented in
			if !isPresented {
				deleteCandidate = nil
			}
		}
		.alert("Missing Required Fields", isPresented: $showValidationAlert) {
			Button("OK") {
				showValidationAlert = false
			}
		} message: {
			Text(validationErrors.map { $0.message }.joined(separator: "\n"))
		}
		.alert("Discard Changes?", isPresented: $showDiscardAlert) {
			Button("Yes, discard", role: .destructive) {
				discardEditing()
			}
			Button("Keep Editing", role: .cancel) {}
		}

		.sheet(isPresented: $showMailComposer) {
			if let strategy = submittingStrategy {
				MailComposer(
					recipient: "marco@marconius.com",
					subject: "Oh Craps Strategy Submission: \(strategy.name)",
					body: submissionEmailBody(for: strategy),
					onFinish: { result in
						if result == .sent {
							store.setSubmitted(id: strategy.id, isSubmitted: true)
						}
						submittingStrategy = nil
					}
				)
			}
		}
	}

	// MARK: - Create Form

	private var createForm: some View {
		VStack(alignment: .leading, spacing: 16) {

			Text("All fields are required except for Notes and Credit.")
				.font(AppTheme.bodyText)

			labeledField("Strategy Name", text: $strategyName, field: .name, next: .buyIn)
			fieldErrorText(for: .name)
			labeledField("Buy-in Amount", text: $buyIn, field: .buyIn, next: .tableMin)
			fieldErrorText(for: .buyIn)
			labeledField("Table Minimum", text: $tableMinimum, field: .tableMin, next: .steps)
			fieldErrorText(for: .tableMin)

			Text("Make a numbered list of steps for your strategy.")

			labeledMultilineField("Steps", text: $stepsText, field: .steps, next: .notes)
			fieldErrorText(for: .steps)
			labeledMultilineField("Notes", text: $notesText, field: .notes, next: .credit)
			labeledField("Credit", text: $credit, field: .credit, next: nil)

			if isEditing {
				HStack(spacing: 16) {
					Button("Save Changes") {
						validateAndSave()
					}
					Button("Cancel") {
						showDiscardAlert = true
					}
				}
			} else {
				HStack(spacing: 16) {
					Button("Reset Form") {
						resetForm()
					}
					Button("Save Strategy") {
						validateAndSave()
					}
				}
			}
		}
		.padding()
		.toolbar {
			ToolbarItemGroup(placement: .keyboard) {
				Spacer()
				Button("Dismiss Keyboard") {
					focusField = nil
				}
			}
		}
	}

	// MARK: - My Strategies

	private var myStrategiesList: some View {
		VStack(alignment: .leading, spacing: 16) {

			ForEach(store.strategies) { strategy in
				StrategyRow(
					strategy: strategy,
					focusedUserStrategyID: $focusedUserStrategyID,
					open: {
						openStrategy(strategy)
					},
					edit: {
						beginEditing(strategy)
					},
					duplicate: {
						duplicateStrategy(strategy)
					},
					submit: {
						beginSubmit(strategy)
					},
					delete: {
						beginDelete(strategy)
					},
					showActions: {
						longPressStrategy = strategy
						showStrategyActions = true
					}
				)
			}
		}
		.padding()
	}

	// MARK: - Actions
	private func beginDelete(_ strategy: UserStrategy) {
		deleteCandidate = strategy
		showDeleteAlert = true
		longPressStrategy = nil
		showStrategyActions = false
	}

	private func validateAndSave() {
		validationErrors = []

		if strategyName.isEmpty {
			validationErrors.append(.missingName)
		}
		if buyIn.isEmpty {
			validationErrors.append(.missingBuyIn)
		}
		if tableMinimum.isEmpty {
			validationErrors.append(.missingTableMinimum)
		}
		if stepsText.isEmpty {
			validationErrors.append(.missingSteps)
		}

		if let firstError = validationErrors.first {
			validationError = firstError
			focusField = firstError.field
			showValidationAlert = true
			return
		}

		saveStrategy()
	}

	private func saveStrategy() {
		let strategy = UserStrategy(
			name: strategyName,
			buyIn: buyIn,
			tableMinimum: tableMinimum,
			steps: stepsText,
			notes: notesText,
			credit: credit
		)

		store.add(strategy)
		mode = .myStrategies
		resetForm()
	}

	private func beginSubmit(_ strategy: UserStrategy) {
		submittingStrategy = strategy
		showSubmitAlert = true
	}

	private func openStrategy(_ strategy: UserStrategy) {
		selectedStrategy = makeDisplayStrategy(from: strategy)
	}

	private func duplicateStrategy(_ strategy: UserStrategy) {
		store.add(
			UserStrategy(
				name: strategy.name + " (Copy)",
				buyIn: strategy.buyIn,
				tableMinimum: strategy.tableMinimum,
				steps: strategy.steps,
				notes: strategy.notes,
				credit: strategy.credit
			)
		)
	}

	private func beginEditing(_ strategy: UserStrategy) {
		isEditing = true
		mode = .create
		editOrigin = editOrigin ?? .myStrategies
		editingOriginalStrategy = strategy
		editingStrategyID = strategy.id
		strategyName = strategy.name
		buyIn = strategy.buyIn
		tableMinimum = strategy.tableMinimum
		stepsText = strategy.steps
		notesText = strategy.notes
		credit = strategy.credit
	}

	private func discardEditing() {
		isEditing = false
		editingStrategyID = nil

		switch editOrigin {
		case .detail(let strategyID):
			if let original = editingOriginalStrategy, original.id == strategyID {
				selectedStrategy = makeDisplayStrategy(from: original)
			}
			mode = .myStrategies
		default:
			mode = .myStrategies
		}

		editOrigin = nil
		editingOriginalStrategy = nil
		focusField = nil
		resetForm()
	}

	private func makeDisplayStrategy(from user: UserStrategy) -> Strategy {
		Strategy(
			id: user.id,
			name: user.name,
			buyInText: user.buyIn,
			tableMinText: user.tableMinimum,
			buyInMin: 0,
			buyInMax: .max,
			tableMinMin: 0,
			tableMinMax: .max,
			notes: user.notes,
			credit: user.credit,
			steps: user.steps
				.split(separator: "\n")
				.map { "§STEP§" + $0 }
		)
	}

	private func submissionEmailBody(for strategy: UserStrategy) -> String {
		"""
		Strategy Name:
		\(strategy.name)

		Buy-in:
		\(strategy.buyIn)

		Table Minimum:
		\(strategy.tableMinimum)

		Steps:
		\(strategy.steps)

		Notes:
		\(strategy.notes)

		Credit:
		\(strategy.credit)
		"""
	}

	private func labeledField(
		_ label: String,
		text: Binding<String>,
		field: Field,
		next: Field?
	) -> some View {
		TextField(label, text: text)
			.focused($focusField, equals: field)
			.submitLabel(next == nil ? .done : .next)
			.onSubmit {
				if let next = next {
					focusField = next
				} else {
					focusField = nil
				}
			}
			.accessibilityHint(fieldErrorMessage(for: field) ?? "")
	}

	private func labeledMultilineField(
		_ label: String,
		text: Binding<String>,
		field: Field,
		next: Field?
	) -> some View {
		TextField(label, text: text, axis: .vertical)
			.focused($focusField, equals: field)
			.submitLabel(next == nil ? .done : .next)
			.onSubmit {
				if let next = next {
					focusField = next
				} else {
					focusField = nil
				}
			}
			.accessibilityHint(fieldErrorMessage(for: field) ?? "")
	}

	private func fieldErrorMessage(for field: Field) -> String? {
		guard isFieldEmpty(field) else {
			return nil
		}

		switch field {
		case .name:
			return validationErrors.contains(.missingName) ? ValidationError.missingName.message : nil
		case .buyIn:
			return validationErrors.contains(.missingBuyIn) ? ValidationError.missingBuyIn.message : nil
		case .tableMin:
			return validationErrors.contains(.missingTableMinimum) ? ValidationError.missingTableMinimum.message : nil
		case .steps:
			return validationErrors.contains(.missingSteps) ? ValidationError.missingSteps.message : nil
		default:
			return nil
		}
	}

	private func fieldErrorText(for field: Field) -> some View {
		if let message = fieldErrorMessage(for: field) {
			return Text("Error: \(message)")
				.font(AppTheme.metadataText)
				.foregroundColor(AppTheme.textPrimary)
				.accessibilityLabel("Error: \(message)")
				.accessibilityAddTraits(.isStaticText)
		}

		return Text("")
			.font(AppTheme.metadataText)
			.accessibilityHidden(true)
	}

	private func isFieldEmpty(_ field: Field) -> Bool {
		switch field {
		case .name:
			return strategyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
		case .buyIn:
			return buyIn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
		case .tableMin:
			return tableMinimum.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
		case .steps:
			return stepsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
		case .notes:
			return notesText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
		case .credit:
			return credit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
		}
	}

	private func resetForm() {
		strategyName = ""
		buyIn = ""
		tableMinimum = ""
		stepsText = ""
		notesText = ""
		credit = ""
		validationErrors = []
		validationError = nil
		showValidationAlert = false
		focusField = .name
	}

	private func focusTitle() {
		titleFocused = true
	}

	private func formattedDate(_ date: Date) -> String {
		DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
	}
}

private struct StrategyRow: View {
	let strategy: UserStrategy
	let focusedUserStrategyID: AccessibilityFocusState<UserStrategy.ID?>.Binding
	let open: () -> Void
	let edit: () -> Void
	let duplicate: () -> Void
	let submit: () -> Void
	let delete: () -> Void
	let showActions: () -> Void

	var body: some View {
		VStack(alignment: .leading) {
			Text(strategy.name)
			Text(
				DateFormatter.localizedString(
					from: strategy.dateCreated,
					dateStyle: .medium,
					timeStyle: .none
				) + (strategy.isSubmitted ? ", Submitted" : "")
			)
		}
		.padding(.vertical, 8)
		.contentShape(Rectangle())
		.onTapGesture {
			open()
		}
		.onLongPressGesture(minimumDuration: 0.45) {
			showActions()
		}
		.accessibilityFocused(focusedUserStrategyID, equals: strategy.id)

		.accessibilityElement(children: .combine)
		.accessibilityAddTraits(.isButton)
		.accessibilityAction(named: Text("Delete \(strategy.name)")) {
			delete()
		}
		.accessibilityAction(named: Text("\(strategy.isSubmitted ? "Resubmit" : "Submit") \(strategy.name)")) {
			submit()
		}
		.accessibilityAction(named: Text("Duplicate \(strategy.name)")) {
			duplicate()
		}
		.accessibilityAction(named: Text("Edit \(strategy.name)")) {
			edit()
		}
	}
}
