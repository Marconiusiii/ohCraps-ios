import Foundation

enum UserStrategyField: Hashable {
	case name
	case buyIn
	case tableMin
	case steps
	case notes
	case credit
}

struct UserStrategyDraft {
	let name: String
	let buyIn: String
	let tableMinimum: String
	let steps: String
	let notes: String
	let credit: String
}

enum UserStrategyValidationIssue: Identifiable, Equatable {
	case required(UserStrategyField, message: String)
	case tooLong(UserStrategyField, label: String, maximum: Int)
	case strategyLimit(maximum: Int)

	var id: String {
		switch self {
		case .required(let field, _):
			return "required-\(field)"
		case .tooLong(let field, _, _):
			return "too-long-\(field)"
		case .strategyLimit:
			return "strategy-limit"
		}
	}

	var field: UserStrategyField? {
		switch self {
		case .required(let field, _), .tooLong(let field, _, _):
			return field
		case .strategyLimit:
			return nil
		}
	}

	var message: String {
		switch self {
		case .required(_, let message):
			return message
		case .tooLong(_, let label, let maximum):
			return "\(label) must be \(maximum) characters or fewer."
		case .strategyLimit(let maximum):
			return "You can save up to \(maximum) strategies. Delete a strategy before creating another one."
		}
	}
}

enum UserStrategyValidation {
	static let maximumNameLength = 120
	static let maximumBuyInLength = 80
	static let maximumTableMinimumLength = 80
	static let maximumStepsLength = 20_000
	static let maximumNotesLength = 10_000
	static let maximumCreditLength = 500
	static let maximumStrategyCount = 500

	static func issues(
		for draft: UserStrategyDraft,
		currentStrategyCount: Int,
		creatingNewStrategy: Bool
	) -> [UserStrategyValidationIssue] {
		var issues: [UserStrategyValidationIssue] = []

		appendRequiredIssue(
			for: draft.name,
			field: .name,
			message: "Please enter a strategy name.",
			to: &issues
		)
		appendRequiredIssue(
			for: draft.buyIn,
			field: .buyIn,
			message: "Please enter a buy-in amount.",
			to: &issues
		)
		appendRequiredIssue(
			for: draft.tableMinimum,
			field: .tableMin,
			message: "Please enter a table minimum.",
			to: &issues
		)
		appendRequiredIssue(
			for: draft.steps,
			field: .steps,
			message: "Please enter at least one step for the strategy.",
			to: &issues
		)

		appendLengthIssue(for: draft.name, field: .name, label: "Strategy Name", maximum: maximumNameLength, to: &issues)
		appendLengthIssue(for: draft.buyIn, field: .buyIn, label: "Buy-in Amount", maximum: maximumBuyInLength, to: &issues)
		appendLengthIssue(for: draft.tableMinimum, field: .tableMin, label: "Table Minimum", maximum: maximumTableMinimumLength, to: &issues)
		appendLengthIssue(for: draft.steps, field: .steps, label: "Steps", maximum: maximumStepsLength, to: &issues)
		appendLengthIssue(for: draft.notes, field: .notes, label: "Notes", maximum: maximumNotesLength, to: &issues)
		appendLengthIssue(for: draft.credit, field: .credit, label: "Credit", maximum: maximumCreditLength, to: &issues)

		if creatingNewStrategy, currentStrategyCount >= maximumStrategyCount {
			issues.append(.strategyLimit(maximum: maximumStrategyCount))
		}

		return issues
	}

	private static func appendRequiredIssue(
		for value: String,
		field: UserStrategyField,
		message: String,
		to issues: inout [UserStrategyValidationIssue]
	) {
		if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			issues.append(.required(field, message: message))
		}
	}

	private static func appendLengthIssue(
		for value: String,
		field: UserStrategyField,
		label: String,
		maximum: Int,
		to issues: inout [UserStrategyValidationIssue]
	) {
		if value.count > maximum {
			issues.append(.tooLong(field, label: label, maximum: maximum))
		}
	}
}
