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
	let dateLastEdited: Date?
	let isSubmitted: Bool

	init(
		id: UUID = UUID(),
		name: String,
		buyIn: String,
		tableMinimum: String,
		steps: String,
		notes: String,
		credit: String,
		dateCreated: Date = Date(),
		dateLastEdited: Date? = nil,
		isSubmitted: Bool = false
	) {
		self.id = id
		self.name = name
		self.buyIn = buyIn
		self.tableMinimum = tableMinimum
		self.steps = steps
		self.notes = notes
		self.credit = credit
		self.dateCreated = dateCreated
		self.dateLastEdited = dateLastEdited
		self.isSubmitted = isSubmitted
	}
	
	enum CodingKeys: String, CodingKey {
		case id
		case name
		case buyIn
		case tableMinimum
		case steps
		case notes
		case credit
		case dateCreated
		case dateLastEdited
		case isSubmitted
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		id = try container.decode(UUID.self, forKey: .id)
		name = try container.decode(String.self, forKey: .name)
		buyIn = try container.decode(String.self, forKey: .buyIn)
		tableMinimum = try container.decode(String.self, forKey: .tableMinimum)
		steps = try container.decode(String.self, forKey: .steps)
		notes = try container.decode(String.self, forKey: .notes)
		credit = try container.decode(String.self, forKey: .credit)
		dateCreated = try container.decode(Date.self, forKey: .dateCreated)
		dateLastEdited = try container.decodeIfPresent(Date.self, forKey: .dateLastEdited)
		isSubmitted = try container.decodeIfPresent(Bool.self, forKey: .isSubmitted) ?? false
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		try container.encode(id, forKey: .id)
		try container.encode(name, forKey: .name)
		try container.encode(buyIn, forKey: .buyIn)
		try container.encode(tableMinimum, forKey: .tableMinimum)
		try container.encode(steps, forKey: .steps)
		try container.encode(notes, forKey: .notes)
		try container.encode(credit, forKey: .credit)
		try container.encode(dateCreated, forKey: .dateCreated)
		try container.encodeIfPresent(dateLastEdited, forKey: .dateLastEdited)
		try container.encode(isSubmitted, forKey: .isSubmitted)
	}

}

