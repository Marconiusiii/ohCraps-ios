import SwiftUI

struct CreateStrategyView: View {

	@State private var strategyName = ""
	@State private var buyIn = ""
	@State private var tableMinimum = ""
	@State private var stepsText = ""
	@State private var notes = ""
	@State private var credit = ""
	@AccessibilityFocusState private var titleFocused: Bool

	@State private var showResetConfirm = false

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


					VStack(alignment: .leading, spacing: 12) {

						TextField("Strategy Name", text: $strategyName)
							.textFieldStyle(.roundedBorder)

						TextField("Buy-in Amount", text: $buyIn)
							.textFieldStyle(.roundedBorder)

						TextField("Table Minimum", text: $tableMinimum)
							.textFieldStyle(.roundedBorder)
					}

					VStack(alignment: .leading, spacing: 8) {
						Text("Strategy Steps")
							.font(AppTheme.sectionHeader)

						TextEditor(text: $stepsText)
							.frame(minHeight: 180)
							.padding(8)
							.background(Color.black.opacity(0.25))
							.overlay(
								RoundedRectangle(cornerRadius: 8)
									.stroke(AppTheme.borderColor)
							)
					}

					VStack(alignment: .leading, spacing: 8) {
						Text("Notes")
							.font(AppTheme.sectionHeader)

						TextEditor(text: $notes)
							.frame(minHeight: 120)
							.padding(8)
							.background(Color.black.opacity(0.25))
							.overlay(
								RoundedRectangle(cornerRadius: 8)
									.stroke(AppTheme.borderColor)
							)
					}

					VStack(alignment: .leading, spacing: 8) {
						Text("Credit")
							.font(AppTheme.sectionHeader)

						TextField("Name or handle", text: $credit)
							.textFieldStyle(.roundedBorder)
					}

					HStack {
						Button("Reset Form") {
							showResetConfirm = true
						}

						Spacer()

						Button("Save Strategy") {
							saveStrategy()
						}
						.disabled(strategyName.isEmpty || stepsText.isEmpty)
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

	private func saveStrategy() {
		// Local-only for now
	}

	private func resetForm() {
		strategyName = ""
		buyIn = ""
		tableMinimum = ""
		stepsText = ""
		notes = ""
		credit = ""
	}
}
