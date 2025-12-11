import SwiftUI

enum TableMinFilter: Int {
	case five = 5
	case ten = 10
	case fifteenPlus = 15
}

enum BuyInFilter: Int {
	case oneHundred = 100
	case threeHundred = 300
	case sixHundred = 600
	case nineHundredPlus = 900
}

struct StrategiesView: View {
	@State private var allStrategies: [Strategy] = StrategyLoader.loadAllStrategies()

	@State private var searchText: String = ""
	
	@FocusState private var focusTableMenu: Bool
	@FocusState private var focusBuyMenu: Bool

	@State private var tableMinFilter: TableMinFilter? = nil
	@State private var buyInFilter: BuyInFilter? = nil
	
	var body: some View {
		NavigationStack {
			VStack(spacing: 12) {
				
				// Search
				TextField("Search strategies", text: $searchText)
					.textFieldStyle(.roundedBorder)
					.padding(.horizontal)
				
				// FILTER MENUS
				HStack {

					// TABLE MINIMUM MENU
					Menu {
						Button("Any") {
							tableMinFilter = nil
							DispatchQueue.main.async { focusTableMenu = true }
						}
						Button("$5") {
							tableMinFilter = .five
							DispatchQueue.main.async { focusTableMenu = true }
						}
						Button("$10") {
							tableMinFilter = .ten
							DispatchQueue.main.async { focusTableMenu = true }
						}
						Button("$15+") {
							tableMinFilter = .fifteenPlus
							DispatchQueue.main.async { focusTableMenu = true }
						}
					} label: {
						AppTheme.menuLabel(text: "Table", value: tableMinFilterLabel)
							.accessibilityLabel("Table Minimum Filter")
							.accessibilityValue(tableMinFilterLabel)
							.focused($focusTableMenu)
					}

					Spacer(minLength: 12)

					// BUY-IN MENU
					Menu {
						Button("Any") {
							buyInFilter = nil
							DispatchQueue.main.async { focusBuyMenu = true }
						}
						Button("$100") {
							buyInFilter = .oneHundred
							DispatchQueue.main.async { focusBuyMenu = true }
						}
						Button("$300") {
							buyInFilter = .threeHundred
							DispatchQueue.main.async { focusBuyMenu = true }
						}
						Button("$600") {
							buyInFilter = .sixHundred
							DispatchQueue.main.async { focusBuyMenu = true }
						}
						Button("$900+") {
							buyInFilter = .nineHundredPlus
							DispatchQueue.main.async { focusBuyMenu = true }
						}
					} label: {
						AppTheme.menuLabel(text: "Buy-in", value: buyInFilterLabel)
							.accessibilityLabel("Buy-in Filter")
							.accessibilityValue(buyInFilterLabel)
							.focused($focusBuyMenu)
					}
				}

				
				// ALPHABETIZED LIST
				List {
					ForEach(sectionedStrategies.keys.sorted(), id: \.self) { letter in
						if let items = sectionedStrategies[letter], !items.isEmpty {
							Section {
								ForEach(items) { strategy in
									NavigationLink(destination: StrategyDetailView(strategy: strategy)) {
										Text(strategy.name)
									}
								}
							} header: {
								Text(String(letter))
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
		switch tableMinFilter {
		case .none: return "Any"
		case .some(.five): return "$5"
		case .some(.ten): return "$10"
		case .some(.fifteenPlus): return "$15+"
		}
	}
	
	private var buyInFilterLabel: String {
		switch buyInFilter {
		case .none: return "Any"
		case .some(.oneHundred): return "$100"
		case .some(.threeHundred): return "$300"
		case .some(.sixHundred): return "$600"
		case .some(.nineHundredPlus): return "$900+"
		}
	}
	
	// MARK: - FILTER LOGIC
	
	private var filteredStrategies: [Strategy] {
		var result = allStrategies
		
		// SEARCH
		if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
			let t = searchText.lowercased()
			result = result.filter {
				$0.name.lowercased().contains(t)
			}
		}
		
		// TABLE MIN FILTER
		if let filt = tableMinFilter {
			result = result.filter { matchesTableMinFilter(strategy: $0, filter: filt) }
		}
		
		// BUY-IN FILTER
		if let filt = buyInFilter {
			result = result.filter { matchesBuyInFilter(strategy: $0, filter: filt) }
		}
		
		return result
	}
	
	private func matchesTableMinFilter(strategy: Strategy, filter: TableMinFilter) -> Bool {
		switch filter {
		case .five:
			return strategy.tableMinMin <= 5 && strategy.tableMinMax >= 5
		case .ten:
			return strategy.tableMinMin <= 10 && strategy.tableMinMax >= 10
		case .fifteenPlus:
			return strategy.tableMinMax >= 15
		}
	}
	
	private func matchesBuyInFilter(strategy: Strategy, filter: BuyInFilter) -> Bool {
		let bucketMin: Int
		let bucketMax: Int
		
		switch filter {
		case .oneHundred:
			bucketMin = 0 ; bucketMax = 299
		case .threeHundred:
			bucketMin = 300 ; bucketMax = 599
		case .sixHundred:
			bucketMin = 600 ; bucketMax = 899
		case .nineHundredPlus:
			bucketMin = 900 ; bucketMax = Int.max
		}
		
		return strategy.buyInMin <= bucketMax && strategy.buyInMax >= bucketMin
	}
	
	// MARK: - ALPHABETIZATION
	
	private var sectionedStrategies: [Character: [Strategy]] {
		let grouped = Dictionary(grouping: filteredStrategies) { strategy in
			strategy.name.uppercased().first ?? "#"
		}
		
		return grouped.mapValues { group in
			group.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
		}
	}
}
