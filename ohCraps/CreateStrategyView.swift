import SwiftUI

struct CreateStrategyView: View {

	private enum FocusField: Hashable {
		case strategyName
		case buyIn
		case tableMinimum
		case steps
		case notes
		case credit
	}

	@State private var strategyName = ""
	@State private var buyIn = ""
	@State private var tableMinimum = ""
	@State private var stepsText = ""
	@State private var notesText = ""
	@State private var credit = ""

	@State private var showResetAlert = false

	@FocusState private var focusedField: FocusField?

	@AccessibilityFocusState private var titleFocused: Bool
	@AccessibilityFocusState private var resetButtonFocused: Bool

	var body: some View {
		ZStack {
			FeltBackground()

			ScrollView {
				VStack(alignment: .leading, spacing: 16) {

					TopNavBar(
						title: "Create Strategy",
						showBack: false,
						backAction: {}
					)
					.accessibilityFocused($titleFocused)

					// Top fields
					labeledTextField(
						label: "Strategy Name",
						text: $strategyName,
						focus: .strategyName
					)

					labeledTextField(
						label: "Buy-in Amount",
						text: $buyIn,
						focus: .buyIn
					)

					labeledTextField(
						label: "Table Minimum",
						text: $tableMinimum,
						focus: .tableMinimum
					)

					// Instruction
					Text("Make a numbered list of steps for your strategy.")
						.font(AppTheme.bodyText)
						.foregroundColor(AppTheme.textPrimary)

					// Steps
					labeledMultilineField(
						label: "Steps",
						text: $stepsText,
						focus: .steps,
						minHeight: 180,
						maxLines: 20
					)

					// Notes
					labeledMultilineField(
						label: "Notes",
						text: $notesText,
						focus: .notes,
						minHeight: 120,
						maxLines: 10
					)

					// Credit – tight spacing like top fields
					labeledTextField(
						label: "Credit",
						text: $credit,
						focus: .credit
					)

					HStack {
						Button("Reset Form") {
							dismissKeyboard()
							showResetAlert = true
						}
						.accessibilityFocused($resetButtonFocused)

						Spacer()

						Button("Save Strategy") {
							dismissKeyboard()
							saveStrategy()
						}
						.disabled(strategyNameTrimmed.isEmpty || stepsTextTrimmed.isEmpty)
					}
					.padding(.top, 8)
				}
				.padding()
			}
		}
		.onAppear {
			focusTitle()
		}
		.toolbar {
			ToolbarItemGroup(placement: .keyboard) {
				Spacer()
				Button("Dismiss") {
					dismissKeyboard()
				}
			}
		}
		.alert("Reset this form?", isPresented: $showResetAlert) {

			Button("Reset Form", role: .destructive) {
				dismissKeyboard()
				resetForm()
				focusTitle()
			}

			Button("Cancel", role: .cancel) {
				dismissKeyboard()
				focusResetButton()
			}
		}
	}

	// MARK: - Field builders

	private func labeledTextField(
		label: String,
		text: Binding<String>,
		focus: FocusField
	) -> some View {
		VStack(alignment: .leading, spacing: 6) {
			Text(label)
				.font(AppTheme.sectionHeader)
				.foregroundColor(AppTheme.textPrimary)
				.accessibilityHidden(true)

			TextField("", text: text)
				.textFieldStyle(.roundedBorder)
				.accessibilityLabel(label)
				.focused($focusedField, equals: focus)
		}
	}

	private func labeledMultilineField(
		label: String,
		text: Binding<String>,
		focus: FocusField,
		minHeight: CGFloat,
		maxLines: Int
	) -> some View {
		VStack(alignment: .leading, spacing: 6) {
			Text(label)
				.font(AppTheme.sectionHeader)
				.foregroundColor(AppTheme.textPrimary)
				.accessibilityHidden(true)

			TextField("", text: text, axis: .vertical)
				.textFieldStyle(.roundedBorder)
				.lineLimit(2...maxLines)
				.frame(minHeight: minHeight, alignment: .top)
				.accessibilityLabel(label)
				.focused($focusedField, equals: focus)
		}
	}

	// MARK: - Helpers

	private var strategyNameTrimmed: String {
		strategyName.trimmingCharacters(in: .whitespacesAndNewlines)
	}

	private var stepsTextTrimmed: String {
		stepsText.trimmingCharacters(in: .whitespacesAndNewlines)
	}

	private func dismissKeyboard() {
		focusedField = nil
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

	private func saveStrategy() {
		// Local-only for now
	}

	private func resetForm() {
		strategyName = ""
		buyIn = ""
		tableMinimum = ""
		stepsText = ""
		notesText = ""
		credit = ""
	}
}

