import SwiftUI
import UIKit

struct CreateStrategyView: View {

	enum Mode: Int, CaseIterable {
		case create
		case myStrategies

		var title: String {
			switch self {
			case .create: return "Create Strategy"
			case .myStrategies: return "My Strategies"
			}
		}
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
			case .missingName:
				return .name
			case .missingBuyIn:
				return .buyIn
			case .missingTableMinimum:
				return .tableMin
			case .missingSteps:
				return .steps
			}
		}
	}

	private enum Field: Hashable {
		case name
		case buyIn
		case tableMin
		case steps
		case notes
		case credit
	}

	@EnvironmentObject private var store: UserStrategyStore

	@State private var mode: Mode = .create
	@State private var lastOpenedStrategyID: UserStrategy.ID?
	@AccessibilityFocusState private var focusedUserStrategyID: UserStrategy.ID?
	@State private var validationError: ValidationError?

	@State private var strategyName = ""
	@State private var buyIn = ""
	@State private var tableMinimum = ""
	@State private var stepsText = ""
	@State private var notesText = ""
	@State private var credit = ""
	@State private var errorField: Field?
	@State private var longPressStrategy: UserStrategy?
	@State private var showStrategyActions = false

	@State private var isEditing = false
	@State private var editingStrategyID: UserStrategy.ID?
	@State private var showCancelEditAlert = false

	@State private var showResetAlert = false
	@State private var selectedStrategy: Strategy?

	@FocusState private var focusField: Field?

	@AccessibilityFocusState private var titleFocused: Bool
	@AccessibilityFocusState private var resetButtonFocused: Bool

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
		.onAppear {
			focusTitle()
		}
		.navigationDestination(item: $selectedStrategy) { strategy in
			StrategyDetailView(strategy: strategy)
				.onDisappear {
					selectedStrategy = nil
				}
		}
		.onChange(of: selectedStrategy) { newValue in
			if newValue == nil, let lastID = lastOpenedStrategyID {
				DispatchQueue.main.async {
					focusedUserStrategyID = lastID
				}
			}
		}
		.toolbar {
			ToolbarItemGroup(placement: .keyboard) {
				Spacer()
				Button("Dismiss Keyboard") {
					dismissKeyboard()
				}
			}
		}
		.confirmationDialog(
			"Strategy Actions",
			isPresented: $showStrategyActions,
			titleVisibility: .visible
		) {
			if let strategy = longPressStrategy {

				Button("Open") {
					openStrategy(strategy)
				}

				Button("Edit") {
					beginEditing(strategy)
				}

				Button("Duplicate") {
					duplicateStrategy(strategy)
				}

				Button("Submit") {
					// Submission flow will be wired later
				}

				Button("Delete", role: .destructive) {
					// Delete flow will be wired later
				}
			}

			Button("Cancel", role: .cancel) {
				longPressStrategy = nil
				showStrategyActions = false
			}
		}

	}

	private var createForm: some View {
		VStack(alignment: .leading, spacing: 16) {
			Text("All fields are required except for Notes and Credit.")
				.font(AppTheme.bodyText)
				.foregroundColor(AppTheme.textPrimary)

			labeledField(
				"Strategy Name",
				text: $strategyName,
				field: .name,
				next: .buyIn
			)

			labeledField(
				"Buy-in Amount",
				text: $buyIn,
				field: .buyIn,
				next: .tableMin
			)

			labeledField(
				"Table Minimum",
				text: $tableMinimum,
				field: .tableMin,
				next: .steps
			)

			Text("Make a numbered list of steps for your strategy.")
				.font(AppTheme.bodyText)
				.foregroundColor(AppTheme.textPrimary)

			labeledMultilineField(
				"Steps",
				text: $stepsText,
				minHeight: 180,
				field: .steps,
				next: .notes
			)

			labeledMultilineField(
				"Notes",
				text: $notesText,
				minHeight: 120,
				field: .notes,
				next: .credit
			)

			labeledField(
				"Credit",
				text: $credit,
				field: .credit,
				next: nil
			)

			HStack {
				Button("Reset Form") {
					showResetAlert = true
				}
				.accessibilityFocused($resetButtonFocused)

				Spacer()

				if isEditing {
					Button("Cancel Edit") {
						showCancelEditAlert = true
					}
				}

				Button(isEditing ? "Save Changes" : "Save Strategy") {
					validateAndSave()
				}
			}
			.padding(.top, 8)
		}
		.padding()
		.alert("Reset this form?", isPresented: $showResetAlert) {
			Button("Reset Form", role: .destructive) {
				resetForm()
				focusTitle()
			}
			Button("Cancel", role: .cancel) {
				focusResetButton()
			}
		}
		.alert(item: $validationError) { error in
			Alert(
				title: Text("Missing Information"),
				message: Text(error.message),
				dismissButton: .default(Text("OK")) {
					errorField = error.field
					DispatchQueue.main.async {
						focusField = error.field
					}
				}
			)
		}
		.alert("Cancel Editing?", isPresented: $showCancelEditAlert) {
			Button("Yes, Cancel", role: .destructive) {
				cancelEditing()
			}
			Button("No, Keep Editing", role: .cancel) {
				DispatchQueue.main.async {
					if focusField == nil {
						focusField = .name
					}
				}
			}
		}
	}

	private var myStrategiesList: some View {
		VStack(alignment: .leading, spacing: 16) {

			if store.strategies.isEmpty {
				Text("You haven't created any strategies yet.")
					.font(AppTheme.bodyText)
					.foregroundColor(AppTheme.textPrimary)
					.padding()
			} else {
				ForEach(store.strategies) { strategy in
					Button {
						openStrategy(strategy)
					} label: {
						VStack(alignment: .leading, spacing: 4) {
							Text(strategy.name)
								.font(AppTheme.cardTitle)
							Text(formattedDate(strategy.dateCreated))
								.font(AppTheme.metadataText)
						}
					}
					.onLongPressGesture {
						longPressStrategy = strategy
						showStrategyActions = true
					}
					.accessibilityFocused(
						$focusedUserStrategyID,
						equals: strategy.id
					)
					.accessibilityAction(named: Text("Edit")) {
						beginEditing(strategy)
					}
				}
				.padding()
			}
		}
	}

	private func validateAndSave() {
		errorField = nil

		if strategyNameTrimmed.isEmpty {
			validationError = .missingName
			return
		}

		if buyInTrimmed.isEmpty {
			validationError = .missingBuyIn
			return
		}

		if tableMinimumTrimmed.isEmpty {
			validationError = .missingTableMinimum
			return
		}

		if stepsTextTrimmed.isEmpty {
			validationError = .missingSteps
			return
		}

		saveStrategy()
	}

	private func labeledField(
		_ label: String,
		text: Binding<String>,
		field: Field,
		next: Field?
	) -> some View {
		VStack(alignment: .leading, spacing: 6) {
			Text(label)
				.font(AppTheme.sectionHeader)
				.foregroundColor(AppTheme.textPrimary)
				.accessibilityHidden(true)

			TextField("", text: text)
				.textFieldStyle(.roundedBorder)
				.accessibilityLabel(label)
				.focused($focusField, equals: field)
				.submitLabel(next == nil ? .done : .next)
				.onSubmit {
					if let nextField = next {
						focusField = nextField
					} else {
						focusField = nil
						dismissKeyboard()
					}
				}
				.overlay(
					RoundedRectangle(cornerRadius: 6)
						.stroke(
							errorField == field ? Color.red : Color.clear,
							lineWidth: 2
						)
				)
				.accessibilityHint(
					errorField == field ? "This field has an error." : ""
				)
				.onChange(of: text.wrappedValue) { _ in
					if errorField == field {
						errorField = nil
					}
				}

			if errorField == field {
				Text("Required.")
					.font(AppTheme.metadataText)
					.foregroundColor(.red)
			}
		}
	}

	private func labeledMultilineField(
		_ label: String,
		text: Binding<String>,
		minHeight: CGFloat,
		field: Field,
		next: Field?
	) -> some View {
		VStack(alignment: .leading, spacing: 6) {
			Text(label)
				.font(AppTheme.sectionHeader)
				.foregroundColor(AppTheme.textPrimary)
				.accessibilityHidden(true)

			TextField("", text: text, axis: .vertical)
				.textFieldStyle(.roundedBorder)
				.frame(minHeight: minHeight, alignment: .top)
				.accessibilityLabel(label)
				.focused($focusField, equals: field)
				.submitLabel(next == nil ? .done : .next)
				.onSubmit {
					if let nextField = next {
						focusField = nextField
					} else {
						focusField = nil
						dismissKeyboard()
					}
				}
				.overlay(
					RoundedRectangle(cornerRadius: 6)
						.stroke(
							errorField == field ? Color.red : Color.clear,
							lineWidth: 2
						)
				)
				.accessibilityHint(
					errorField == field ? "This field has an error." : ""
				)
				.onChange(of: text.wrappedValue) { _ in
					if errorField == field {
						errorField = nil
					}
				}

			if errorField == field {
				Text("Required.")
					.font(AppTheme.metadataText)
					.foregroundColor(.red)
			}
		}
	}

	private func saveStrategy() {
		errorField = nil
		validationError = nil

		focusField = nil
		dismissKeyboard()

		if isEditing, let id = editingStrategyID {
			store.update(
				id: id,
				name: strategyNameTrimmed,
				buyIn: buyInTrimmed,
				tableMinimum: tableMinimumTrimmed,
				steps: stepsTextTrimmed,
				notes: notesText,
				credit: credit
			)

			finishEditingAndReturn(focusID: id)
			return
		}

		let userStrat = UserStrategy(
			name: strategyNameTrimmed,
			buyIn: buyInTrimmed,
			tableMinimum: tableMinimumTrimmed,
			steps: stepsTextTrimmed,
			notes: notesText,
			credit: credit
		)

		store.add(userStrat)
		resetForm()
		mode = .myStrategies

		DispatchQueue.main.async {
			focusedUserStrategyID = userStrat.id
		}
	}

	private func resetForm() {
		focusField = nil
		dismissKeyboard()

		strategyName = ""
		buyIn = ""
		tableMinimum = ""
		stepsText = ""
		notesText = ""
		credit = ""
	}

	private func cancelEditing() {
		if let id = editingStrategyID {
			finishEditingAndReturn(focusID: id)
		} else {
			isEditing = false
			editingStrategyID = nil
			resetForm()
			mode = .myStrategies
			focusTitle()
		}
	}

	private func finishEditingAndReturn(focusID: UserStrategy.ID) {
		isEditing = false
		editingStrategyID = nil
		resetForm()
		mode = .myStrategies

		DispatchQueue.main.async {
			focusedUserStrategyID = focusID
		}
	}

	private func beginEditing(_ strategy: UserStrategy) {
		isEditing = true
		editingStrategyID = strategy.id

		strategyName = strategy.name
		buyIn = strategy.buyIn
		tableMinimum = strategy.tableMinimum
		stepsText = strategy.steps
		notesText = strategy.notes
		credit = strategy.credit

		mode = .create

		DispatchQueue.main.async {
			focusField = .name
		}
	}

	private func makeDisplayStrategy(from user: UserStrategy) -> Strategy {
		let steps = user.steps
			.split(separator: "\n")
			.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
			.filter { !$0.isEmpty }
			.map { "§STEP§" + $0 }

		return Strategy(
			id: user.id,
			name: user.name,
			buyInText: user.buyIn,
			tableMinText: user.tableMinimum,
			buyInMin: 0,
			buyInMax: Int.max,
			tableMinMin: 0,
			tableMinMax: Int.max,
			notes: user.notes,
			credit: user.credit,
			steps: steps
		)
	}

	private func openStrategy(_ userStrategy: UserStrategy) {
		lastOpenedStrategyID = userStrategy.id
		selectedStrategy = makeDisplayStrategy(from: userStrategy)
	}

	private func duplicateStrategy(_ strategy: UserStrategy) {
		let copy = UserStrategy(
			name: strategy.name + " (Copy)",
			buyIn: strategy.buyIn,
			tableMinimum: strategy.tableMinimum,
			steps: strategy.steps,
			notes: strategy.notes,
			credit: strategy.credit
		)

		store.add(copy)
	}


	private func dismissKeyboard() {
		UIApplication.shared.sendAction(
			#selector(UIResponder.resignFirstResponder),
			to: nil,
			from: nil,
			for: nil
		)
	}

	private func focusTitle() {
		titleFocused = false
		DispatchQueue.main.async {
			titleFocused = true
		}
	}

	private func focusResetButton() {
		resetButtonFocused = false
		DispatchQueue.main.async {
			resetButtonFocused = true
		}
	}

	private var strategyNameTrimmed: String {
		strategyName.trimmingCharacters(in: .whitespacesAndNewlines)
	}

	private var buyInTrimmed: String {
		buyIn.trimmingCharacters(in: .whitespacesAndNewlines)
	}

	private var tableMinimumTrimmed: String {
		tableMinimum.trimmingCharacters(in: .whitespacesAndNewlines)
	}

	private var stepsTextTrimmed: String {
		stepsText.trimmingCharacters(in: .whitespacesAndNewlines)
	}

	private func formattedDate(_ date: Date) -> String {
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		return formatter.string(from: date)
	}
}

