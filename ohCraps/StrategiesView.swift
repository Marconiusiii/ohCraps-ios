import SwiftUI

// MARK: - FILTER ENUMS

enum TableMinFilter: CaseIterable {
	case five, ten, fifteenPlus
	
	var label: String {
		switch self {
		case .five: return "$5"
		case .ten: return "$10"
		case .fifteenPlus: return "$15+"
		}
	}
}

enum BuyInFilter: CaseIterable {
	case oneHundred, threeHundred, sixHundred, nineHundredPlus
	
	var label: String {
		switch self {
		case .oneHundred: return "$100"
		case .threeHundred: return "$300"
		case .sixHundred: return "$600"
		case .nineHundredPlus: return "$900+"
		}
	}
}


// MARK: - SAFER SECTION KEY

enum SectionKey: Hashable, Comparable {
	case number            // "#"
	case letter(Character) // A–Z
	
	var display: String {
		switch self {
		case .number: return "#"
		case .letter(let c): return String(c)
		}
	}
	
	static func < (lhs: SectionKey, rhs: SectionKey) -> Bool {
		switch (lhs, rhs) {
		case (.number, .letter): return true
		case (.letter, .number): return false
		case (.number, .number): return false
		case let (.letter(a), .letter(b)): return a < b
		}
	}
}


// MARK: - VIEW

struct StrategiesView: View {
	
	@State private var allStrategies: [Strategy] = StrategyLoader.loadAllStrategies()
	@State private var searchText: String = ""
	
	@State private var tableMinFilter: TableMinFilter? = nil
	@State private var buyInFilter: BuyInFilter? = nil
	
	@FocusState private var focusTableMenu: Bool
	@FocusState private var focusBuyMenu: Bool
	
	
	var body: some View {
		NavigationStack {
			VStack(spacing: 16) {
				
				// SEARCH
				TextField("Search strategies", text: $searchText)
					.textFieldStyle(.roundedBorder)
					.padding(.horizontal)
					.accessibilityLabel("Search strategies")
				
				
				// FILTER ROW
				HStack {
					
					// TABLE MINIMUM FILTER
					Menu {
						Button("Off") {
							tableMinFilter = nil
							DispatchQueue.main.async { focusTableMenu = true }
						}
						ForEach(TableMinFilter.allCases, id: \.self) { filter in
							Button(filter.label) {
								tableMinFilter = filter
								DispatchQueue.main.async { focusTableMenu = true }
							}
						}
					} label: {
						AppTheme.menuLabel(text: "Table", value: tableMinFilterLabel)
							.accessibilityAddTraits(.isButton)
					}
					.accessibilityLabel("Table Minimum Filter")
					.accessibilityValue(tableMinFilterLabel)
					.focused($focusTableMenu)
					
					
					// BUY-IN FILTER
					Menu {
						Button("Off") {
							buyInFilter = nil
							DispatchQueue.main.async { focusBuyMenu = true }
						}
						ForEach(BuyInFilter.allCases, id: \.self) { filter in
							Button(filter.label) {
								buyInFilter = filter
								DispatchQueue.main.async { focusBuyMenu = true }
							}
						}
					} label: {
						AppTheme.menuLabel(text: "Buy-in", value: buyInFilterLabel)
							.accessibilityAddTraits(.isButton)
					}
					.accessibilityLabel("Buy-in Filter")
					.accessibilityValue(buyInFilterLabel)
					.focused($focusBuyMenu)
				}
				.padding(.horizontal)
				
				
				// STRATEGY LIST
				List {
					ForEach(sectionOrder, id: \.self) { section in
						if let items = sectionedStrategies[section], !items.isEmpty {
							Section {
								ForEach(items) { strategy in
									NavigationLink(destination: StrategyDetailView(strategy: strategy)) {
										Text(strategy.name)
									}
								}
							} header: {
								Text(section.display)
									.font(.title2)
									.accessibilityAddTraits(.isHeader)
							}
						}
					}
				}
				.listStyle(.plain)
				
			}
			.navigationTitle("Oh Craps!")
			.navigationBarTitleDisplayMode(.large)
		}
	}
	
	
	// MARK: - FILTER LABELS
	
	private var tableMinFilterLabel: String {
		tableMinFilter?.label ?? "Off"
	}
	
	private var buyInFilterLabel: String {
		buyInFilter?.label ?? "Off"
	}
	
	
	// MARK: - FILTERED STRATEGIES
	
	private var filteredStrategies: [Strategy] {
		var result = allStrategies
		
		let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
		if !query.isEmpty {
			result = result.filter { $0.name.lowercased().contains(query) }
		}
		
		if let f = tableMinFilter {
			result = result.filter { matchesTableMinFilter(strategy: $0, filter: f) }
		}
		
		if let f = buyInFilter {
			result = result.filter { matchesBuyInFilter(strategy: $0, filter: f) }
		}
		
		return result
	}
	
	
	// MARK: - TABLE MINIMUM FILTER
	
	private func matchesTableMinFilter(strategy: Strategy, filter: TableMinFilter) -> Bool {
		switch filter {
		case .five: return strategy.tableMinMin <= 5 && strategy.tableMinMax >= 5
		case .ten: return strategy.tableMinMin <= 10 && strategy.tableMinMax >= 10
		case .fifteenPlus: return strategy.tableMinMax >= 15
		}
	}
	
	
	// MARK: - BUY-IN FILTER
	
	private func matchesBuyInFilter(strategy: Strategy, filter: BuyInFilter) -> Bool {
		let bucket: (Int, Int)
		
		switch filter {
		case .oneHundred: bucket = (0, 299)
		case .threeHundred: bucket = (300, 599)
		case .sixHundred: bucket = (600, 899)
		case .nineHundredPlus: bucket = (900, Int.max)
		}
		
		return strategy.buyInMin <= bucket.1 &&
			   strategy.buyInMax >= bucket.0
	}
	
	
	// MARK: - NAME NORMALIZATION
	
	private func normalizedName(_ strategy: Strategy) -> String {
		let trimmed = strategy.name.trimmingCharacters(in: .whitespaces)
		let noDollar = trimmed.drop(while: { $0 == "$" })
		return String(noDollar)
	}
	
	
	// MARK: - NUMERIC PREFIX FOR SORTING
	
	private func numericPrefix(of name: String) -> Int? {
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
	
	
	// MARK: - SECTIONED STRATEGIES WITH NUMERIC SORTING
	
	private var sectionedStrategies: [SectionKey: [Strategy]] {
		
		let grouped: [SectionKey: [Strategy]] = Dictionary(grouping: filteredStrategies) { strategy in
			let n = normalizedName(strategy)
			guard let first = n.first else { return .number }
			
			if first.isNumber { return .number }
			if first.isLetter { return .letter(Character(first.uppercased())) }
			return .number
		}
		
		return grouped.mapValues { group in
			group.sorted { a, b in
				let na = normalizedName(a)
				let nb = normalizedName(b)
				
				let numA = numericPrefix(of: na)
				let numB = numericPrefix(of: nb)
				
				switch (numA, numB) {
					
				case let (x?, y?):
					if x != y { return x < y }
					return na.localizedCaseInsensitiveCompare(nb) == .orderedAscending
					
				case (.some, .none):
					return true
					
				case (.none, .some):
					return false
					
				case (.none, .none):
					return na.localizedCaseInsensitiveCompare(nb) == .orderedAscending
				}
			}
		}
	}
	
	
	// MARK: - SECTION ORDER
	
	private var sectionOrder: [SectionKey] {
		sectionedStrategies.keys.sorted()
	}
}
