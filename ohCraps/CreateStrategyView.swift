import SwiftUI
import UIKit
import MessageUI

struct CreateStrategyView: View {
	@Binding var hideTabBar: Bool

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
		case myStrategies(UserStrategy.ID)
		case detail(UserStrategy.ID)
	}

	private enum ActionOrigin {
		case list(UserStrategy.ID)
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
	@State private var showSaveOptionsAlert = false

	@State private var selectedStrategy: Strategy?
	@State private var selectedDetailFocus: DetailFocusTarget = .title
	@State private var detailFocusRevision = 0
	@State private var listEditOriginID: UserStrategy.ID?
	@State private var pendingListFocusID: UserStrategy.ID?
	@State private var pendingScrollID: UserStrategy.ID?
	@State private var restoreWork: DispatchWorkItem?
	@State private var userByID: [UserStrategy.ID: UserStrategy] = [:]
	@State private var viewByID: [UserStrategy.ID: Strategy] = [:]
	@State private var suppressDetailClose = false
	@State private var keepBarHiddenOnClose = false
	@State private var focusModePickerAfterDelete = false
	@State private var deleteOrigin: ActionOrigin?
	@State private var submitOrigin: ActionOrigin?
	@State private var didConfirmDelete = false
	@State private var sharePayload: SharePayload?
	@State private var shareOriginID: UserStrategy.ID?

	@FocusState private var focusField: Field?
	@AccessibilityFocusState private var focusedUserStrategyID: UserStrategy.ID?
	@AccessibilityFocusState private var modePickerFocused: Bool
	@AccessibilityFocusState private var editTitleFocus: Bool
	private var screenTitle: String {
		if isEditing {
			let trimmed = strategyName.trimmingCharacters(in: .whitespacesAndNewlines)
			return trimmed.isEmpty ? "Editing Strategy" : "Editing \(trimmed)"
		}
		return "Create Strategy"
	}

	private var strategyActionsTitle: String {
		if let strategy = longPressStrategy {
			return "\(strategy.name) Actions"
		}
		return "Strategy Actions"
	}

	var body: some View {
		ZStack {
			FeltBackground()

			VStack(spacing: 0) {

				TopNavBar(
					title: screenTitle,
					showBack: false,
					backAction: {}
				)
				.accessibilityFocused($editTitleFocus)

				if !isEditing {
					Picker("Mode", selection: $mode) {
						Text("Create Strategy").tag(Mode.create)
						Text("My Strategies").tag(Mode.myStrategies)
					}
					.pickerStyle(.segmented)
					.padding()
					.accessibilityFocused($modePickerFocused)
				}

				switch mode {
				case .create:
					ScrollView {
						createForm
					}
				case .myStrategies:
					myStrategiesList
				}
			}
		}
		.onAppear {
			hideTabBar = isEditing
			syncCaches()
		}
		.onDisappear {
			hideTabBar = false
		}
		.onChange(of: isEditing) { editing in
			hideTabBar = editing
			if !editing {
				editTitleFocus = false
			}
		}
		.onChange(of: hideTabBar) { hidden in
			guard !hidden else { return }
			scheduleRowFocus()
		}
		.onChange(of: pendingListFocusID) { strategyID in
			guard strategyID != nil else { return }
			scheduleRowFocus()
		}
		.onChange(of: mode) { newMode in
			guard newMode == .myStrategies else { return }
			scheduleRowFocus()
		}
		.onReceive(store.$strategies) { _ in
			syncCaches()
			scheduleRowFocus()
		}
		.navigationDestination(item: $selectedStrategy) { strategy in
			detailScreen(strategy)
		}

		.confirmationDialog(
			strategyActionsTitle,
			isPresented: $showStrategyActions,
			titleVisibility: .visible
		) {
			if let strategy = longPressStrategy {
				Button("Edit") {
					beginEditing(strategy, origin: .myStrategies(strategy.id))
				}

				Button("Duplicate") {
					duplicateStrategy(strategy, origin: .list(strategy.id))
				}

				Button(strategy.isSubmitted ? "Resubmit" : "Submit") {
					beginSubmit(strategy, origin: .list(strategy.id))
				}

				Button("Share Strategy") {
					beginShare(strategy, originID: strategy.id)
				}

				Button("Delete \(strategy.name)", role: .destructive) {
					beginDelete(strategy, origin: .list(strategy.id))
				}

				Button("Dismiss") {
					focusedUserStrategyID = strategy.id
					listEditOriginID = strategy.id
					longPressStrategy = nil
					showStrategyActions = false
				}
			}
		}
		.onChange(of: showStrategyActions) { isPresented in
			if !isPresented {
				if let id = listEditOriginID {
					focusedUserStrategyID = id
				}
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
				handleSubmitCancelled()
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
					didConfirmDelete = true
					store.delete(strategy)
					handleDeleteConfirmed(strategy)
				}
				deleteCandidate = nil
			}
		}
		.onChange(of: showDeleteAlert) { isPresented in
			if !isPresented {
				if !didConfirmDelete {
					handleDeleteCancelled()
				}
				didConfirmDelete = false
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
		.alert("Save Strategy", isPresented: $showSaveOptionsAlert) {
			Button("Save Original") {
				saveEditedStrategy()
			}
			Button("Create New") {
				saveStrategy()
			}
			Button("Cancel", role: .cancel) {}
		}

		.sheet(isPresented: $showMailComposer, onDismiss: {
			if pendingListFocusID != nil {
				scheduleRowFocus()
			}
		}) {
			if let strategy = submittingStrategy {
					MailComposer(
						recipient: "marco@marconius.com",
						subject: "Oh Craps! iOS Strategy Submission - \(strategy.name)",
						body: submissionEmailBody(for: strategy),
						onFinish: { result in
						if result == .sent {
							store.setSubmitted(id: strategy.id, isSubmitted: true)
						}
						handleSubmitFinished(result: result, strategyID: strategy.id)
					}
				)
			}
		}
		.sheet(item: $sharePayload, onDismiss: {
			if let id = shareOriginID {
				DispatchQueue.main.async {
					focusedUserStrategyID = id
					shareOriginID = nil
				}
			}
		}) { payload in
			ShareSheet(payload: payload)
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
		ScrollViewReader { proxy in
			List {
				if store.strategies.isEmpty {
					Text("No saved strategies yet.")
						.font(AppTheme.bodyText)
				}

				ForEach(store.strategies) { strategy in
					NavigationLink(
						destination: detailScreen(viewByID[strategy.id] ?? makeDisplayStrategy(from: strategy))
					) {
						StrategyRow(
							strategy: strategy,
							edit: {
								beginEditing(strategy, origin: .myStrategies(strategy.id))
							},
							duplicate: {
								duplicateStrategy(strategy, origin: .list(strategy.id))
							},
							submit: {
								beginSubmit(strategy, origin: .list(strategy.id))
							},
							share: {
								beginShare(strategy, originID: strategy.id)
							},
							delete: {
								beginDelete(strategy, origin: .list(strategy.id))
							},
							showActions: {
								longPressStrategy = strategy
								listEditOriginID = strategy.id
								showStrategyActions = true
							}
						)
					}
					.id(strategy.id)
					.accessibilityFocused($focusedUserStrategyID, equals: strategy.id)
					.onAppear {
						if pendingListFocusID == strategy.id {
							focusRow(strategy.id)
						}
					}
					.listRowBackground(Color.black.opacity(0.45))
					.simultaneousGesture(TapGesture().onEnded {
						pendingListFocusID = strategy.id
						modePickerFocused = false
					})
				}
			}
			.onChange(of: pendingScrollID) { id in
				guard let id else { return }
				focusRowNow(id, proxy: proxy)
			}
			.onAppear {
				if let id = pendingScrollID ?? pendingListFocusID {
					focusRowNow(id, proxy: proxy)
				}
			}
			.listStyle(.plain)
			.scrollContentBackground(.hidden)
			.background(Color.clear)
		}
	}

	// MARK: - Actions
	private func beginDelete(_ strategy: UserStrategy, origin: ActionOrigin) {
		deleteCandidate = strategy
		deleteOrigin = origin
		focusModePickerAfterDelete = false
		pendingListFocusID = nil

		if case .list = origin, let index = store.strategies.firstIndex(where: { $0.id == strategy.id }) {
			let strategies = store.strategies
			if strategies.count > 1 {
				if index < strategies.count - 1 {
					pendingListFocusID = strategies[index + 1].id
				} else {
					pendingListFocusID = strategies[index - 1].id
				}
			} else {
				focusModePickerAfterDelete = true
			}
		}
		showDeleteAlert = true
		longPressStrategy = nil
		showStrategyActions = false
	}

	private func handleDeleteConfirmed(_ deleted: UserStrategy) {
		switch deleteOrigin {
		case .list:
			mode = .myStrategies
			if focusModePickerAfterDelete {
				DispatchQueue.main.async {
					modePickerFocused = true
				}
			} else {
				tryRestoreRowFocus()
			}
		case .detail:
			pendingListFocusID = nil
			selectedStrategy = nil
			mode = .myStrategies
			DispatchQueue.main.async {
				modePickerFocused = true
				}
		case nil:
			break
		}

		deleteOrigin = nil
		if listEditOriginID == deleted.id {
			listEditOriginID = nil
		}
	}

	private func handleDeleteCancelled() {
		if case .detail(let strategyID) = deleteOrigin,
		   let strategy = userByID[strategyID] {
			selectedDetailFocus = .actions
			detailFocusRevision += 1
			selectedStrategy = makeDisplayStrategy(from: strategy)
		}
		deleteOrigin = nil
	}

	private func handleSubmitCancelled() {
		switch submitOrigin {
		case .list(let strategyID):
			pendingListFocusID = strategyID
			pendingScrollID = nil
			DispatchQueue.main.async {
				pendingScrollID = strategyID
				scheduleRowFocus()
			}
		case .detail(let strategyID):
			if let strategy = userByID[strategyID] {
				selectedDetailFocus = .actions
				detailFocusRevision += 1
				selectedStrategy = makeDisplayStrategy(from: strategy)
			}
		case nil:
			break
		}

		submittingStrategy = nil
		submitOrigin = nil
	}

	private func handleSubmitFinished(result: MFMailComposeResult, strategyID: UserStrategy.ID) {
		if result == .sent {
			switch submitOrigin {
			case .list:
				pendingListFocusID = strategyID
				pendingScrollID = nil
				DispatchQueue.main.async {
					pendingScrollID = strategyID
				}
			case .detail:
				if let strategy = userByID[strategyID] {
					selectedDetailFocus = .title
					detailFocusRevision += 1
					selectedStrategy = makeDisplayStrategy(from: strategy)
				}
			case nil:
				break
			}
		} else {
			handleSubmitCancelled()
			return
		}

		submittingStrategy = nil
		submitOrigin = nil
	}

	private func beginShare(_ strategy: UserStrategy, originID: UserStrategy.ID) {
		shareOriginID = originID
		sharePayload = SharePayload(
			strategyName: strategy.name,
			text: StrategyShareFormatter.shareText(for: strategy)
		)
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

		if isEditing {
			showSaveOptionsAlert = true
			return
		}

		saveStrategy()
	}

	private func saveStrategy() {
		let finalName = newSaveName()
		let strategy = UserStrategy(
			name: finalName,
			buyIn: buyIn,
			tableMinimum: tableMinimum,
			steps: stepsText,
			notes: notesText,
			credit: credit
		)

		store.add(strategy)
		finishSaveFlow(savedOriginalID: nil, createdStrategy: strategy)
	}

	private func newSaveName() -> String {
		let typed = strategyName.trimmingCharacters(in: .whitespacesAndNewlines)
		guard isEditing,
			  let original = editingOriginalStrategy?.name.trimmingCharacters(in: .whitespacesAndNewlines),
			  !typed.isEmpty,
			  typed == original
		else {
			return strategyName
		}

		let used = Set(store.strategies.map { $0.name.lowercased() })
		let start = nextNumStart(for: typed)
		var n = start
		while true {
			let base = numBase(for: typed)
			let candidate = base.isEmpty ? "\(n)" : "\(base) \(n)"
			if !used.contains(candidate.lowercased()) {
				return candidate
			}
			n += 1
		}
	}

	private func nextNumStart(for name: String) -> Int {
		if let hit = name.wholeMatch(of: /^(.*?)(?:\s+)?(\d+)$/),
		   let n = Int(hit.2) {
			return n + 1
		}
		return 1
	}

	private func numBase(for name: String) -> String {
		if let hit = name.wholeMatch(of: /^(.*?)(?:\s+)?(\d+)$/) {
			return String(hit.1).trimmingCharacters(in: .whitespacesAndNewlines)
		}
		return name
	}

	private func saveEditedStrategy() {
		guard let editingID = editingStrategyID else {
			saveStrategy()
			return
		}

		store.update(
			id: editingID,
			name: strategyName,
			buyIn: buyIn,
			tableMinimum: tableMinimum,
			steps: stepsText,
			notes: notesText,
			credit: credit
		)

		if let updated = store.strategies.first(where: { $0.id == editingID }) {
			finishSaveFlow(savedOriginalID: editingID, createdStrategy: nil, updatedOriginal: updated)
		} else {
			finishSaveFlow(savedOriginalID: editingID, createdStrategy: nil)
		}
	}

	private func finishSaveFlow(
		savedOriginalID: UserStrategy.ID?,
		createdStrategy: UserStrategy?,
		updatedOriginal: UserStrategy? = nil
	) {
		let origin = editOrigin

		isEditing = false
		editTitleFocus = false
		editingStrategyID = nil
		mode = .myStrategies
		resetForm(false)

		switch origin {
			case .myStrategies(let id):
				if let created = createdStrategy {
					pendingListFocusID = created.id
					pendingScrollID = nil
					DispatchQueue.main.async {
						pendingScrollID = created.id
					}
				} else if let savedID = savedOriginalID {
					pendingListFocusID = savedID
					pendingScrollID = nil
					DispatchQueue.main.async {
						pendingScrollID = savedID
					}
				} else {
					pendingListFocusID = id
					pendingScrollID = nil
					DispatchQueue.main.async {
						pendingScrollID = id
					}
				}
		case .detail(let id):
			let target: UserStrategy?
			if let created = createdStrategy {
				target = created
			} else if let updated = updatedOriginal {
				target = updated
			} else {
				target = userByID[id]
			}

			if let strategy = target {
				selectedDetailFocus = .title
				detailFocusRevision += 1
				selectedStrategy = makeDisplayStrategy(from: strategy)
			}
		case nil:
			if let created = createdStrategy {
				pendingListFocusID = created.id
			}
		}

		editOrigin = nil
		editingOriginalStrategy = nil
		DispatchQueue.main.async {
			scheduleRowFocus()
		}
	}

	private func beginSubmit(_ strategy: UserStrategy, origin: ActionOrigin) {
		submittingStrategy = strategy
		submitOrigin = origin
		showSubmitAlert = true
	}

	private func submitFromDetail(_ strategy: UserStrategy) {
		submittingStrategy = strategy
		submitOrigin = .detail(strategy.id)
		showMailComposer = true
	}

	private func deleteFromDetail(_ strategy: UserStrategy) {
		deleteOrigin = .detail(strategy.id)
		didConfirmDelete = true
		store.delete(strategy)
		handleDeleteConfirmed(strategy)
		didConfirmDelete = false
		deleteCandidate = nil
	}

	private func detailScreen(_ strategy: Strategy) -> some View {
		let userStrategy = userByID[strategy.id]
		return StrategyDetailView(
			strategy: strategy,
			hideTabBar: $hideTabBar,
			keepBarHiddenOnClose: $keepBarHiddenOnClose,
			userStrategy: userStrategy,
			edit: {
				if let userStrategy = userStrategy {
					suppressDetailClose = true
					keepBarHiddenOnClose = true
					selectedStrategy = nil
					DispatchQueue.main.async {
						beginEditing(userStrategy, origin: .detail(userStrategy.id))
					}
				}
			},
			duplicate: {
				if let userStrategy = userStrategy {
					duplicateStrategy(userStrategy, origin: .detail(userStrategy.id))
				}
			},
			submit: {
				if let userStrategy = userStrategy {
					submitFromDetail(userStrategy)
				}
			},
			delete: {
				if let userStrategy = userStrategy {
					deleteFromDetail(userStrategy)
				}
			},
			onShow: {
				if let id = userStrategy?.id {
					pendingListFocusID = id
				}
				modePickerFocused = false
			},
			onGone: {
				if suppressDetailClose {
					suppressDetailClose = false
					DispatchQueue.main.async {
						if isEditing {
							hideTabBar = true
						}
					}
					return
				}
			},
			initialAccessibilityFocus: selectedDetailFocus,
			focusRevision: detailFocusRevision
		)
	}

	private func duplicateStrategy(_ strategy: UserStrategy, origin: ActionOrigin) {
		let copied = UserStrategy(
			name: strategy.name + " (Copy)",
			buyIn: strategy.buyIn,
			tableMinimum: strategy.tableMinimum,
			steps: strategy.steps,
			notes: strategy.notes,
			credit: strategy.credit
		)
		store.add(copied)

		switch origin {
		case .list:
			mode = .myStrategies
			pendingListFocusID = copied.id
		case .detail:
			selectedDetailFocus = .title
			detailFocusRevision += 1
			selectedStrategy = makeDisplayStrategy(from: copied)
		}
	}

	private func beginEditing(_ strategy: UserStrategy, origin: EditOrigin) {
		isEditing = true
		mode = .create
		editOrigin = origin
		editingOriginalStrategy = strategy
		editingStrategyID = strategy.id
		strategyName = strategy.name
		buyIn = strategy.buyIn
		tableMinimum = strategy.tableMinimum
		stepsText = strategy.steps
		notesText = strategy.notes
		credit = strategy.credit
		focusField = nil
		DispatchQueue.main.async {
			editTitleFocus = true
		}
	}

	private func discardEditing() {
		isEditing = false
		editTitleFocus = false
		editingStrategyID = nil

		switch editOrigin {
		case .detail(let strategyID):
			if let current = userByID[strategyID] {
				selectedDetailFocus = .actions
				detailFocusRevision += 1
				selectedStrategy = makeDisplayStrategy(from: current)
			} else if let original = editingOriginalStrategy, original.id == strategyID {
				selectedDetailFocus = .actions
				detailFocusRevision += 1
				selectedStrategy = makeDisplayStrategy(from: original)
			}
			mode = .myStrategies
		case .myStrategies(let strategyID):
			mode = .myStrategies
			pendingListFocusID = strategyID
		default:
			mode = .myStrategies
		}

		editOrigin = nil
		editingOriginalStrategy = nil
		focusField = nil
		resetForm(false)
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

	private func resetForm(_ putFocus: Bool = true) {
		strategyName = ""
		buyIn = ""
		tableMinimum = ""
		stepsText = ""
		notesText = ""
		credit = ""
		validationErrors = []
		validationError = nil
		showValidationAlert = false
		focusField = putFocus ? .name : nil
	}

	private func tryRestoreRowFocus() {
		guard mode == .myStrategies, let targetID = pendingListFocusID else {
			return
		}
		guard selectedStrategy == nil else {
			return
		}
		guard !isEditing else {
			return
		}
		guard !showDeleteAlert, !showSubmitAlert, !showStrategyActions else {
			return
		}
		guard store.strategies.contains(where: { $0.id == targetID }) else {
			return
		}
		focusRow(targetID)
	}

	private func focusRow(_ id: UserStrategy.ID) {
		if focusedUserStrategyID == id {
			if pendingListFocusID == id {
				pendingListFocusID = nil
			}
			return
		}
		modePickerFocused = false
		DispatchQueue.main.async {
			focusedUserStrategyID = id
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
				if focusedUserStrategyID == id, pendingListFocusID == id {
					pendingListFocusID = nil
				}
			}
		}
	}

	private func focusRowNow(_ id: UserStrategy.ID, proxy: ScrollViewProxy) {
		DispatchQueue.main.async {
			withAnimation(nil) {
				proxy.scrollTo(id, anchor: .center)
			}
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
				focusRow(id)
				pendingScrollID = nil
			}
		}
	}

	private func scheduleRowFocus() {
		restoreWork?.cancel()
		let work = DispatchWorkItem {
			tryRestoreRowFocus()
		}
		restoreWork = work
		DispatchQueue.main.async(execute: work)
	}

	private func syncCaches() {
		var nextUser: [UserStrategy.ID: UserStrategy] = [:]
		var nextView: [UserStrategy.ID: Strategy] = [:]
		nextUser.reserveCapacity(store.strategies.count)
		nextView.reserveCapacity(store.strategies.count)
		for strategy in store.strategies {
			nextUser[strategy.id] = strategy
			nextView[strategy.id] = makeDisplayStrategy(from: strategy)
		}
		userByID = nextUser
		viewByID = nextView
	}

	private func formattedDate(_ date: Date) -> String {
		DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
	}
}

private struct StrategyRow: View {
	let strategy: UserStrategy
	let edit: () -> Void
	let duplicate: () -> Void
	let submit: () -> Void
	let share: () -> Void
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
		.onLongPressGesture(minimumDuration: 0.45) {
			showActions()
		}

		.accessibilityElement(children: .combine)
		.accessibilityAddTraits(.isButton)
		.accessibilityAction(named: Text("Delete \(strategy.name)")) {
			delete()
		}
		.accessibilityAction(named: Text("Share Strategy")) {
			share()
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
