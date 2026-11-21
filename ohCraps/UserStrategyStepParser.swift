import Foundation

enum UserStrategyStepParser {
	private static let orderedPrefixPattern = #"^\d+[\.\)]\s+(.+)$"#

	static func orderedContent(from value: String) -> String? {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		guard
			let regex = try? NSRegularExpression(pattern: orderedPrefixPattern),
			let match = regex.firstMatch(
				in: trimmed,
				options: [],
				range: NSRange(location: 0, length: trimmed.utf16.count)
			),
			match.numberOfRanges > 1,
			let contentRange = Range(match.range(at: 1), in: trimmed)
		else {
			return nil
		}

		let content = String(trimmed[contentRange])
			.trimmingCharacters(in: .whitespacesAndNewlines)
		return content.isEmpty ? nil : content
	}

	static func displayContent(from value: String) -> String {
		orderedContent(from: value)
			?? value.trimmingCharacters(in: .whitespacesAndNewlines)
	}
}
