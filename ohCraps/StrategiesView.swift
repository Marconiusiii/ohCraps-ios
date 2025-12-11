import SwiftUI
import UIKit

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

enum SectionKey: Hashable, Comparable {
	case number
	case letter(Character)
	
	var display: String {
		switch self {
		case .number: return "#"
		case .letter(let c): return String(c)
		}
	}
	
	static func < (lhs: SectionKey, rhs: SectionKey) -> Bool {
		switch (lhs, rhs) {
		case (.number, .letter):
			return true
		case (.letter, .number):
			return false
		case (.number, .number):
			return false
		case let (.letter(a), .letter(b)):
			return a < b
		}
	}
}

struct StrategiesView: View {
	
	@State private var allStrategies: [Strategy] = []
	@State private var isLoading = true
	
	@State private var searchText = ""
	@State private var isSearching = false
	@FocusState private var isSearchFocused: Bool
	
	@State private var tableMinFilter: TableMinFilter? = nil
	@State private var buyInFilter: BuyInFilter? = nil
	
	@AccessibilityFocusState private var isTableMenuFocused: Bool
	@AccessibilityFocusState private var isBuyMenuFocused: Bool
	@AccessibilityFocusState private var titleNeedsFocus: Bool
	
	@State private var announceWorkItem: DispatchWorkItem?
	
	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				TopNavBar(
					title: "Oh Craps!",
					showBack: false,
					backAction: {}
				)
				.accessibilityFocused($titleNeedsFocus)
				
				if isLoading {
					loadingView
				} else {
					contentView
				}
			}
			.onAppear {
				loadStrategies()
			}
		}
	}
	
	private var loadingView: some View {
		VStack(spacing: 20) {
			ProgressView()
				.progressViewStyle(.circular)
			
			Text("Loading Strategies…")
				.font(.headline)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.onAppear {
			UIAccessibility.post(notification: .announcement, argument: "Loading strategies")
		}
	}
	
	private var contentView: some View {
		VStack(spacing: 16) {
			searchBar
			filterRow
			
			List {
				ForEach(sectionOrder, id: \.self) { section in
					if let items = sectionedStrategies[section], !items.isEmpty {
						Section {
							ForEach(items) { strategy in
								NavigationLink(
									destination: StrategyDetailView(strategy: strategy)
								) {
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
	}
	
	private var searchBar: some View {
		HStack {
			TextField(
				"Search strategies",
				text: $searchText,
				onEditingChanged: { editing in
					isSearching = editing
				}
			)
			.textFieldStyle(.roundedBorder)
			.focused($isSearchFocused)
			.submitLabel(.search)
			.onChange(of: searchText) { _ in
				announceSearchResultsSoon()
			}
			.onSubmit {
				announceSearchResults()
			}
			.toolbar {
				ToolbarItemGroup(placement: .keyboard) {
					Spacer()
					Button("Dismiss Keyboard") {
						isSearchFocused = false
					}
					.accessibilityLabel("Dismiss keyboard")
				}
			}
			
			if isSearching {
				Button("Cancel") {
					searchText = ""
					isSearching = false
					isSearchFocused = false
					announceSearchResults()
				}
				.buttonStyle(.borderless)
				.transition(.opacity)
			}
		}
		.padding(.horizontal)
	}
	
	private var filterRow: some View {
		HStack {
			
			Menu {
				Button("Off") {
					tableMinFilter = nil
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
						isTableMenuFocused = true
					}
				}
				ForEach(TableMinFilter.allCases, id: \.self) { filter in
					Button(filter.label) {
						tableMinFilter = filter
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
							isTableMenuFocused = true
						}
					}
				}
			} label: {
				AppTheme.menuLabel(text: "Table", value: tableMinFilterLabel)
					.accessibilityFocused($isTableMenuFocused)
			}
			.accessibilityLabel("Table Minimum Filter")
			.accessibilityValue(tableMinFilterLabel)
			
			Menu {
				Button("Off") {
					buyInFilter = nil
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
						isBuyMenuFocused = true
					}
				}
				ForEach(BuyInFilter.allCases, id: \.self) { filter in
					Button(filter.label) {
						buyInFilter = filter
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
							isBuyMenuFocused = true
						}
					}
				}
			} label: {
				AppTheme.menuLabel(text: "Buy-in", value: buyInFilterLabel)
					.accessibilityFocused($isBuyMenuFocused)
			}
			.accessibilityLabel("Buy-in Filter")
			.accessibilityValue(buyInFilterLabel)
			
		}
		.padding(.horizontal)
	}
	
	private var tableMinFilterLabel: String {
		tableMinFilter?.label ?? "Off"
	}
	
	private var buyInFilterLabel: String {
		buyInFilter?.label ?? "Off"
	}
	
	private var filteredStrategies: [Strategy] {
		var result = allStrategies
		
		let q = searchText
			.trimmingCharacters(in: .whitespacesAndNewlines)
			.lowercased()
		
		if !q.isEmpty {
			result = result.filter { $0.name.lowercased().contains(q) }
		}
		
		if let f = tableMinFilter {
			result = result.filter { matchesTableMinFilter(strategy: $0, filter: f) }
		}
		
		if let f = buyInFilter {
			result = result.filter { matchesBuyInFilter(strategy: $0, filter: f) }
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
	
	private func normalizedName(_ strategy: Strategy) -> String {
		let trimmed = strategy.name.trimmingCharacters(in: .whitespaces)
		return String(trimmed.drop(while: { $0 == "$" }))
	}
	
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
	
	private var sectionedStrategies: [SectionKey: [Strategy]] {
		let grouped = Dictionary(grouping: filteredStrategies) { strategy -> SectionKey in
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
	
	private var sectionOrder: [SectionKey] {
		sectionedStrategies.keys.sorted()
	}
	
	private func announceSearchResults() {
		let count = filteredStrategies.count
		let msg = count == 1 ? "Showing 1 strategy" : "Showing \(count) strategies"
		UIAccessibility.post(notification: .announcement, argument: msg)
	}
	
	private func announceSearchResultsSoon() {
		announceWorkItem?.cancel()
		let task = DispatchWorkItem { announceSearchResults() }
		announceWorkItem = task
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: task)
	}
	
	private func loadStrategies() {
		DispatchQueue.global(qos: .userInitiated).async {
			let loaded = StrategyLoader.loadAllStrategies()
			
			DispatchQueue.main.async {
				allStrategies = loaded
				isLoading = false
				
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
					titleNeedsFocus = true
				}
			}
		}
	}
}

