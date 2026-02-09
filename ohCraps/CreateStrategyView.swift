import SwiftUI

struct CreateStrategyView: View {

	@State private var strategyName = ""
	@State private var buyIn = ""
	@State private var tableMinimum = ""
	@State private var stepsText = ""
	@State private var notesText = ""
	@State private var credit = ""
	@AccessibilityFocusState private var titleFocused: Bool

	@State private var showResetConfirm = false

	private let stepsPlaceholder = "1. Step 1\n2. Step 2\n3. Step 3..."
	private let notesPlaceholder = "(optional)"

	var body: some View {
		ZStack {
			FeltBackground()

			ScrollView {
				VStack(alignment: .leading, spacing: 20) {

					TopNavBar(
						title: "Create Strategy",
						showBack: false,
						backAction: {}
					)
					.accessibilityFocused($titleFocused)

					VStack(alignment: .leading, spacing: 8) {
						Text("Strategy Name")
							.font(AppTheme.sectionHeader)
							.foregroundColor(AppTheme.textPrimary)
							.accessibilityHidden(true)
						TextField("", text: $strategyName)
							.textFieldStyle(.roundedBorder)
							.accessibilityLabel("Strategy Name")
					}

					VStack(alignment: .leading, spacing: 8) {
						Text("Buy-in Amount")
							.font(AppTheme.sectionHeader)
							.foregroundColor(AppTheme.textPrimary)
							.accessibilityHidden(true)

						TextField("", text: $buyIn)
							.textFieldStyle(.roundedBorder)
							.accessibilityLabel("Buy-in Amount")
					}

					VStack(alignment: .leading, spacing: 8) {
						Text("Table Minimum")
							.font(AppTheme.sectionHeader)
							.foregroundColor(AppTheme.textPrimary)
							.accessibilityHidden(true)

						TextField("", text: $tableMinimum)
							.textFieldStyle(.roundedBorder)
							.accessibilityLabel("Table Minimum")
					}

					Text("Make a numbered list of steps for your strategy.")
						.font(AppTheme.bodyText)
						.foregroundColor(AppTheme.textPrimary)

					VStack(alignment: .leading, spacing: 8) {
						Text("Steps")
							.font(AppTheme.sectionHeader)
							.foregroundColor(AppTheme.textPrimary)
							.accessibilityHidden(true)

						TextField("", text: $stepsText, prompt: Text(stepsPlaceholder), axis: .vertical)
							.textFieldStyle(.roundedBorder)
							.lineLimit(2...20)
							.frame(minHeight: 220, alignment: .top)
							.accessibilityLabel("Steps")
					}

					VStack(alignment: .leading, spacing: 8) {
						Text("Notes")
							.font(AppTheme.sectionHeader)
							.foregroundColor(AppTheme.textPrimary)
							.accessibilityHidden(true)

						TextField("", text: $notesText, prompt: Text(notesPlaceholder), axis: .vertical)
							.textFieldStyle(.roundedBorder)
							.lineLimit(2...10)
							.frame(minHeight: 140, alignment: .top)
							.accessibilityLabel("Notes")
					}

					VStack(alignment: .leading, spacing: 8) {
						Text("Credit")
							.font(AppTheme.sectionHeader)
							.foregroundColor(AppTheme.textPrimary)
							.accessibilityHidden(true)

						TextField("", text: $credit)
							.textFieldStyle(.roundedBorder)
							.accessibilityLabel("Credit")
					}

					HStack {
						Button("Reset Form") {
							showResetConfirm = true
						}

						Spacer()

						Button("Save Strategy") {
							saveStrategy()
						}
						.disabled(strategyNameTrimmed.isEmpty || stepsTextTrimmed.isEmpty)
					}
				}
				.padding()
			}
		}
		.confirmationDialog(
			"Reset this form?",
			isPresented: $showResetConfirm,
			titleVisibility: .visible
		) {
			Button("Reset Form", role: .destructive) {
				resetForm()
			}
			Button("Cancel", role: .cancel) {}
		}
	}

	private var strategyNameTrimmed: String {
		strategyName.trimmingCharacters(in: .whitespacesAndNewlines)
	}

	private var stepsTextTrimmed: String {
		stepsText.trimmingCharacters(in: .whitespacesAndNewlines)
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

