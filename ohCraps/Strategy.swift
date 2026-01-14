import Foundation

struct Strategy: Identifiable {
	let id: UUID
	
	let name: String
	
	// Display strings exactly as written in your .txt files
	let buyInText: String
	let tableMinText: String
	
	// Parsed numeric ranges for filtering
	let buyInMin: Int
	let buyInMax: Int
	
	let tableMinMin: Int
	let tableMinMax: Int
	
	let notes: String
	let credit: String
	let steps: [String]
}

// Helper for parsing "$X" or "$X-$Y"
func parseRange(_ text: String) -> (min: Int, max: Int) {
	let cleaned = text.replacingOccurrences(of: "$", with: "")
	
	if cleaned.contains("-") {
		let parts = cleaned.split(separator: "-")
		let minVal = Int(parts[0].trimmingCharacters(in: .whitespaces)) ?? 0
		let maxVal = Int(parts[1].trimmingCharacters(in: .whitespaces)) ?? 0
		return (minVal, maxVal)
	} else {
		let value = Int(cleaned.trimmingCharacters(in: .whitespaces)) ?? 0
		return (value, value)
	}
}
// Temporary placeholder data so the app compiles and runs
struct SampleData {
	static let strategies: [Strategy] = [
		Strategy(
			id: UUID(),
			name: "Example Strategy",
			buyInText: "$100-$300",
			tableMinText: "$5-$15",
			buyInMin: 100,
			buyInMax: 300,
			tableMinMin: 5,
			tableMinMax: 15,
			notes: "Example notes go here.",
			credit: "Strategy credits",
			steps: [
				"Step one goes here.",
				"Step two goes here."
			]
		)
	]
}
