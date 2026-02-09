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
		case missingSteps

		var id: Self { self }

		var message: String {
			switch self {
			case .missingName:
				return "Please enter a strategy name."
			case .missingSteps:
				return "Please enter at least one step for the strategy."
			}
		}

		var field: Field {
			switch self {
			case .missingName:
				return .name
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

				Picker("Mode", selection: $mode) {
					Text("Create Strategy").tag(Mode.create)
					Text("My Strategies").tag(Mode.myStrategies)
				}
				.pickerStyle(.segmented)
				.padding()

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

				Button("Save Strategy") {
					validateAndSave()
				}
//				.disabled(strategyNameTrimmed.isEmpty || stepsTextTrimmed.isEmpty)
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
					DispatchQueue.main.async {
						focusField = error.field
					}
				}
			)
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
					.accessibilityFocused(
						$focusedUserStrategyID,
						equals: strategy.id
					)
				}
				.padding()
			}
		}
	}
	private func validateAndSave() {
		if strategyNameTrimmed.isEmpty {
			validationError = .missingName
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
		}
	}

	private func saveStrategy() {
		focusField = nil
		dismissKeyboard()

		let userStrat = UserStrategy(
			name: strategyNameTrimmed,
			buyIn: buyIn,
			tableMinimum: tableMinimum,
			steps: stepsText,
			notes: notesText,
			credit: credit
		)

		store.add(userStrat)
		resetForm()
		mode = .myStrategies
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

	private var stepsTextTrimmed: String {
		stepsText.trimmingCharacters(in: .whitespacesAndNewlines)
	}

	private func formattedDate(_ date: Date) -> String {
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		return formatter.string(from: date)
	}
}

