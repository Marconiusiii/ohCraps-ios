import Foundation

struct UserStrategyHTML {

	static func makeHTML(
		name: String,
		buyInText: String,
		tableMinText: String,
		notes: String,
		credit: String,
		steps: [String]
	) -> String {

		var html = ""
		
		html += "<h3>\(escape(name))</h3>\n"
		html += "<p>Buy-in: \(escape(buyInText))</p>\n"
		html += "<p>Table Minimum: \(escape(tableMinText))</p>\n"

		if !notes.isEmpty {
			html += "<p>Notes: \(escape(notes))</p>\n"
		}

		if !credit.isEmpty {
			html += "<p>Credit: \(escape(credit))</p>\n"
		}

		html += "<ol>\n"
		for step in steps {
			let trimmed = step.trimmingCharacters(in: .whitespacesAndNewlines)
			guard !trimmed.isEmpty else { continue }
			html += "<li>\(escape(trimmed))</li>\n"
		}
		html += "</ol>\n"

		return html
	}

	private static func escape(_ text: String) -> String {
		text
			.replacingOccurrences(of: "&", with: "&amp;")
			.replacingOccurrences(of: "<", with: "&lt;")
			.replacingOccurrences(of: ">", with: "&gt;")
	}
}
