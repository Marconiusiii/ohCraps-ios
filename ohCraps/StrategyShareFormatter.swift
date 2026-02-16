import Foundation

enum StrategyShareFormatter {
	private enum Token {
		case ordered(String)
		case bullet(String)
		case paragraph(String)
		case paragraphBreak
	}

	static func shareText(for strategy: Strategy) -> String {
		let tokens = tokens(from: strategy)
		return buildText(
			name: strategy.name,
			buyIn: strategy.buyInText,
			tableMinimum: strategy.tableMinText,
			stepsText: renderSteps(tokens: tokens),
			notes: strategy.notes,
			credit: strategy.credit
		)
	}

	static func shareText(for strategy: UserStrategy) -> String {
		let tokens = tokens(from: strategy)
		return buildText(
			name: strategy.name,
			buyIn: strategy.buyIn,
			tableMinimum: strategy.tableMinimum,
			stepsText: renderSteps(tokens: tokens),
			notes: strategy.notes,
			credit: strategy.credit
		)
	}

	private static func buildText(
		name: String,
		buyIn: String,
		tableMinimum: String,
		stepsText: String,
		notes: String,
		credit: String
	) -> String {
		var sections: [String] = []

		sections.append("Strategy Name:\n\(name)")
		sections.append("Buy-in:\n\(buyIn)")
		sections.append("Table Minimum:\n\(tableMinimum)")
		sections.append("Steps:\n\(stepsText)")

		if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			sections.append("Notes:\n\(notes)")
		}

		if !credit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			sections.append("Credit:\n\(credit)")
		}

		return sections.joined(separator: "\n\n")
	}

	private static func tokens(from strategy: Strategy) -> [Token] {
		var tokens: [Token] = []
		for raw in strategy.steps {
			let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
			guard !trimmed.isEmpty else {
				tokens.append(.paragraphBreak)
				continue
			}

			if let text = textAfterTag("§STEP§", in: trimmed) {
				tokens.append(.ordered(text))
			} else if let text = textAfterTag("§BULLET§", in: trimmed) {
				tokens.append(.bullet(text))
			} else if let text = textAfterTag("§H4§", in: trimmed) {
				tokens.append(.paragraph(text))
			} else if let text = textAfterTag("§PARA§", in: trimmed) {
				tokens.append(.paragraph(text))
			} else {
				tokens.append(.paragraph(trimmed))
			}
		}
		return tokens
	}

	private static func tokens(from strategy: UserStrategy) -> [Token] {
		let lines = strategy.steps.components(separatedBy: .newlines)
		var tokens: [Token] = []

		for raw in lines {
			let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
			if trimmed.isEmpty {
				tokens.append(.paragraphBreak)
				continue
			}

			if let ordered = orderedLineContent(from: trimmed) {
				tokens.append(.ordered(ordered))
			} else if let bullet = bulletLineContent(from: trimmed) {
				tokens.append(.bullet(bullet))
			} else {
				tokens.append(.paragraph(trimmed))
			}
		}

		return tokens
	}

	private static func renderSteps(tokens: [Token]) -> String {
		var lines: [String] = []
		var orderedIndex: Int?
		var previousWasParagraphBreak = false

		for token in tokens {
			switch token {
			case .paragraphBreak:
				orderedIndex = nil
				previousWasParagraphBreak = true
				appendBlankLineIfNeeded(&lines)
			case .paragraph(let text):
				orderedIndex = nil
				appendBlankLineIfNeeded(&lines)
				lines.append(text)
				lines.append("")
				previousWasParagraphBreak = false
			case .ordered(let text):
				if previousWasParagraphBreak {
					orderedIndex = nil
				}
				let nextIndex = (orderedIndex ?? 0) + 1
				lines.append("\(nextIndex). \(text)")
				orderedIndex = nextIndex
				previousWasParagraphBreak = false
			case .bullet(let text):
				lines.append("- \(text)")
				previousWasParagraphBreak = false
			}
		}

		while lines.last == "" {
			lines.removeLast()
		}

		return lines.joined(separator: "\n")
	}

	private static func appendBlankLineIfNeeded(_ lines: inout [String]) {
		guard let last = lines.last, !last.isEmpty else {
			return
		}
		lines.append("")
	}

	private static func textAfterTag(_ tag: String, in value: String) -> String? {
		guard value.hasPrefix(tag) else { return nil }
		let text = value.replacingOccurrences(of: tag, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
		return text.isEmpty ? nil : text
	}

	private static func orderedLineContent(from value: String) -> String? {
		let pattern = #"^\d+[\.\)]\s+(.+)$"#
		guard let regex = try? NSRegularExpression(pattern: pattern) else {
			return nil
		}
		let range = NSRange(location: 0, length: value.utf16.count)
		guard let match = regex.firstMatch(in: value, options: [], range: range), match.numberOfRanges > 1 else {
			return nil
		}
		let capture = match.range(at: 1)
		guard let swiftRange = Range(capture, in: value) else {
			return nil
		}
		let text = String(value[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
		return text.isEmpty ? nil : text
	}

	private static func bulletLineContent(from value: String) -> String? {
		let markers = ["- ", "* ", "• "]
		for marker in markers where value.hasPrefix(marker) {
			let text = String(value.dropFirst(marker.count)).trimmingCharacters(in: .whitespacesAndNewlines)
			return text.isEmpty ? nil : text
		}
		return nil
	}
}
