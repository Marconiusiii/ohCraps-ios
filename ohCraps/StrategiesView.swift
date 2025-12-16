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
		case .oneHundred: return "$0 to $299"
		case .threeHundred: return "$300 to $599"
		case .sixHundred: return "$600 to $899"
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

	private var searchTextField: some View {
		TextField("Search strategies", text: $searchText,
				  prompt: Text("Search strategies")
					  .foregroundColor(Color.white.opacity(0.8)))
			.textFieldStyle(.plain)
			.padding(8)
			.background(Color(red: 0.05, green: 0.12, blue: 0.07))
			.cornerRadius(8)
			.foregroundColor(.white)
			.focused($isSearchFocused)
			.submitLabel(.search)
	}

	
	var body: some View {
		NavigationStack {
			ZStack {
				FeltBackground()

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
				.tint(.white)
			
			Text("Loading Strategies…")
				.font(AppTheme.cardTitle)
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
										.foregroundColor(.white)
										.fixedSize(horizontal: false, vertical: true)
								}
								.listRowBackground(Color.black.opacity(0.45))
							}
						} header: {
							Text(section.display)
								.font(AppTheme.sectionHeader)
								.background(Color.black.opacity(0.6))
								.cornerRadius(6)
								.accessibilityAddTraits(.isHeader)
								.accessibilityIdentifier(sectionID(for: section))
						}
						

					}
				}
			}
			.listStyle(.plain)
			.scrollContentBackground(.hidden)
			.background(Color.clear)
		}
	}
	
	private var searchBar: some View {
		VStack(alignment: .leading, spacing: 8) {
			searchTextField
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
				.buttonStyle(.plain)
				.foregroundColor(.white)
				.transition(.opacity)
			}
		}
		.padding(.horizontal)
	}

	private var filterRow: some View {
		ViewThatFits {
			// Preferred layout: horizontal
			HStack(spacing: 12) {
				tableMinMenu
				buyInMenu
			}

			// Fallback layout: vertical
			VStack(alignment: .leading, spacing: 8) {
				tableMinMenu
				buyInMenu
			}
		}
		.padding(.horizontal)
		.padding(.vertical, 8)
		.background(Color.black.opacity(0.4))
	}
	
	private var tableMinMenu: some View {
		Menu {
			Button("Any") {
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
		.accessibilityLabel("Table Minimum")
		.accessibilityValue(tableMinFilterLabel)
	}
	
	private var buyInMenu: some View {
		Menu {
			Button("Any") {
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
		.accessibilityLabel("Buy-in")
		.accessibilityValue(buyInFilterLabel)
	}



	private var tableMinFilterLabel: String {
		tableMinFilter?.label ?? "Any"
	}
	
	private var buyInFilterLabel: String {
		buyInFilter?.label ?? "Any"
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
	private func sectionID(for key: SectionKey) -> String {
		switch key {
		case .number:
			return "section-number"
		case .letter(let c):
			return "section-\(c)"
		}
	}

}
