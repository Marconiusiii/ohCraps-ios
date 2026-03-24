import Foundation

struct Strategy: Identifiable, Hashable {
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
	let searchName: String
	let sortName: String
	let sortNum: Int?

	init(
		id: UUID,
		name: String,
		buyInText: String,
		tableMinText: String,
		buyInMin: Int,
		buyInMax: Int,
		tableMinMin: Int,
		tableMinMax: Int,
		notes: String,
		credit: String,
		steps: [String],
		searchName: String? = nil,
		sortName: String? = nil,
		sortNum: Int? = nil
	) {
		self.id = id
		self.name = name
		self.buyInText = buyInText
		self.tableMinText = tableMinText
		self.buyInMin = buyInMin
		self.buyInMax = buyInMax
		self.tableMinMin = tableMinMin
		self.tableMinMax = tableMinMax
		self.notes = notes
		self.credit = credit
		self.steps = steps
		self.searchName = searchName ?? name.lowercased()
		let derivedSort = sortName ?? Strategy.makeSortName(name)
		self.sortName = derivedSort
		self.sortNum = sortNum ?? Strategy.makeSortNum(derivedSort)
	}

	private static func makeSortName(_ name: String) -> String {
		var value = name.trimmingCharacters(in: .whitespaces)
		value = String(value.drop(while: { $0 == "$" }))
		if value.lowercased().hasPrefix("the ") {
			value = String(value.dropFirst(4))
		}
		return value
	}

	private static func makeSortNum(_ name: String) -> Int? {
		var digits = ""
		for ch in name {
			if ch.isNumber {
				digits.append(ch)
			} else {
				break
			}
		}
		return digits.isEmpty ? nil : Int(digits)
	}
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
