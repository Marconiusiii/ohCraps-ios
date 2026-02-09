import SwiftUI

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

	@EnvironmentObject private var store: UserStrategyStore

	@State private var mode: Mode = .create

	@State private var strategyName = ""
	@State private var buyIn = ""
	@State private var tableMinimum = ""
	@State private var stepsText = ""
	@State private var notesText = ""
	@State private var credit = ""

	@State private var showResetAlert = false

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
	}

	// MARK: - Create Form

	private var createForm: some View {
		VStack(alignment: .leading, spacing: 16) {

			labeledField("Strategy Name", text: $strategyName)
			labeledField("Buy-in Amount", text: $buyIn)
			labeledField("Table Minimum", text: $tableMinimum)

			Text("Make a numbered list of steps for your strategy.")
				.font(AppTheme.bodyText)
				.foregroundColor(AppTheme.textPrimary)

			labeledMultilineField("Steps", text: $stepsText, minHeight: 180)
			labeledMultilineField("Notes", text: $notesText, minHeight: 120)
			labeledField("Credit", text: $credit)

			HStack {
				Button("Reset Form") {
					showResetAlert = true
				}
				.accessibilityFocused($resetButtonFocused)

				Spacer()

				Button("Save Strategy") {
					saveStrategy()
				}
				.disabled(strategyNameTrimmed.isEmpty || stepsTextTrimmed.isEmpty)
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
	}

	// MARK: - My Strategies

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
				}
				.padding()
			}
		}
	}

	// MARK: - Field Helpers

	private func labeledField(_ label: String, text: Binding<String>) -> some View {
		VStack(alignment: .leading, spacing: 6) {
			Text(label)
				.font(AppTheme.sectionHeader)
				.foregroundColor(AppTheme.textPrimary)
				.accessibilityHidden(true)

			TextField("", text: text)
				.textFieldStyle(.roundedBorder)
				.accessibilityLabel(label)
		}
	}

	private func labeledMultilineField(
		_ label: String,
		text: Binding<String>,
		minHeight: CGFloat
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
		}
	}

	// MARK: - Actions

	private func saveStrategy() {
		let strategy = UserStrategy(
			name: strategyNameTrimmed,
			buyIn: buyIn,
			tableMinimum: tableMinimum,
			steps: stepsTextTrimmed,
			notes: notesText,
			credit: credit
		)

		store.add(strategy)
		resetForm()
		mode = .myStrategies
	}

	private func resetForm() {
		strategyName = ""
		buyIn = ""
		tableMinimum = ""
		stepsText = ""
		notesText = ""
		credit = ""
	}

	private func openStrategy(_ strategy: UserStrategy) {
		// Next step: map to StrategyDetailView
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

