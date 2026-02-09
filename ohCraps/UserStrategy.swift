import Foundation

struct UserStrategy: Identifiable, Codable {
	let id: UUID
	let name: String
	let buyIn: String
	let tableMinimum: String
	let steps: String
	let notes: String
	let credit: String
	let dateCreated: Date
	
	init(
		id: UUID = UUID(),
		name: String,
		buyIn: String,
		tableMinimum: String,
		steps: String,
		notes: String,
		credit: String,
		dateCreated: Date = Date()
	) {
		self.id = id
		self.name = name
		self.buyIn = buyIn
		self.tableMinimum = tableMinimum
		self.steps = steps
		self.notes = notes
		self.credit = credit
		self.dateCreated = dateCreated
	}
}
