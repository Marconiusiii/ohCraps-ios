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
	@Binding var hideTabBar: Bool

	@State private var allStrategies: [Strategy] = []
	@State private var isLoading = true
	@State private var filteredStrategiesCache: [Strategy] = []
	@State private var sectionedStrategiesCache: [SectionKey: [Strategy]] = [:]
	@State private var sectionOrderCache: [SectionKey] = []
	@State private var searchNameIndex: [Strategy.ID: String] = [:]
	
	private var shouldStackFilters: Bool {
		dynamicTypeSize >= .accessibility1
	}

	@State private var searchText = ""
	
	@Environment(\.dynamicTypeSize) private var dynamicTypeSize

	@FocusState private var isSearchFocused: Bool
	
	private enum FocusTarget {
		case tableMenu
		case buyInMenu
	}

	@State private var pendingFocusTarget: FocusTarget?

	private var shouldShowCancel: Bool {
		isSearchFocused || !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	}

	@State private var tableMinFilter: TableMinFilter? = nil
	@State private var buyInFilter: BuyInFilter? = nil
	
	private enum A11yFocus {
		case tableMin
		case buyIn
	}

	@AccessibilityFocusState private var a11yFocus: A11yFocus?

	@State private var announceWorkItem: DispatchWorkItem?

	private var searchTextField: some View {
		ZStack(alignment: .leading) {
			// Visual placeholder (sighted users only)
			if searchText.isEmpty {
				Text("Search strategies")
					.foregroundColor(Color.white.opacity(0.8))
					.padding(.leading, 12)
					.accessibilityHidden(true)
			}

			TextField("", text: $searchText)
				.textFieldStyle(.plain)
				.padding(8)
				.background(Color(red: 0.05, green: 0.12, blue: 0.07))
				.cornerRadius(8)
				.foregroundColor(.white)
				.focused($isSearchFocused)
				.submitLabel(.search)
				.accessibilityLabel("Search Strategies")
				.accessibilityValue(searchText)
		}
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
					if isLoading {
						loadingView
					} else {
						contentView
					}
				}
			}
			.onAppear {
				if allStrategies.isEmpty {
					loadStrategies()
				} else {
					rebuildSearchNameIndex()
					rebuildDerivedStrategies()
					isLoading = false
				}
			}
			.onChange(of: allStrategies) { _ in
				rebuildSearchNameIndex()
				rebuildDerivedStrategies()
			}
			.onChange(of: searchText) { _ in
				rebuildDerivedStrategies()
			}
			.onChange(of: tableMinFilter) { _ in
				rebuildDerivedStrategies()
			}
			.onChange(of: buyInFilter) { _ in
				rebuildDerivedStrategies()
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
				.onChange(of: tableMinFilter) { _ in
					restorePendingAccessibilityFocus()
				}
				.onChange(of: buyInFilter) { _ in
					restorePendingAccessibilityFocus()
				}

			List {
				ForEach(sectionOrderCache, id: \.self) { section in
					if let items = sectionedStrategiesCache[section], !items.isEmpty {
						Section {
							ForEach(items) { strategy in
								NavigationLink(
									destination: StrategyDetailView(
										strategy: strategy,
										hideTabBar: $hideTabBar
									)
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
		ViewThatFits {
			// Preferred: horizontal
			HStack(alignment: .center, spacing: 12) {
				searchTextField
				if shouldShowCancel {
					cancelSearchButton
				}
			}

			// Fallback: vertical
			VStack(alignment: .leading, spacing: 8) {
				searchTextField
				if shouldShowCancel {
					cancelSearchButton
				}
			}
		}
		.padding(.horizontal)
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
	}
	private var cancelSearchButton: some View {
		Button("Cancel") {
			searchText = ""
			isSearchFocused = false
			announceSearchResults()
		}
		.buttonStyle(.plain)
		.foregroundColor(.white)
		.accessibilityLabel("Clear search")
	}

	private var filterRow: some View {
		Group {
			if shouldStackFilters {
				VStack(alignment: .leading, spacing: 8) {
					tableMinMenu
					buyInMenu
				}
			} else {
				HStack(spacing: 12) {
					tableMinMenu
					buyInMenu
				}
			}
		}
		.padding(.horizontal)
		.padding(.vertical, 8)
		.background(Color.black.opacity(0.4))
	}

	private var tableMinMenu: some View {
		Menu {
			Button("Any") {
				pendingFocusTarget = .tableMenu
				tableMinFilter = nil
			}

			ForEach(TableMinFilter.allCases, id: \.self) { filter in
				Button(filter.label) {
					pendingFocusTarget = .tableMenu
					tableMinFilter = filter
				}
			}
		} label: {
			AppTheme.menuLabel(text: "Table", value: tableMinFilterLabel)
				.accessibilityFocused($a11yFocus, equals: .tableMin)
		}
		.accessibilityLabel("Table Minimum")
		.accessibilityValue(tableMinFilterLabel)
	}
	
	private var buyInMenu: some View {
		Menu {
			Button("Any") {
				pendingFocusTarget = .buyInMenu
				buyInFilter = nil
			}

			ForEach(BuyInFilter.allCases, id: \.self) { filter in
				Button(filter.label) {
					pendingFocusTarget = .buyInMenu
					buyInFilter = filter
				}
			}
		} label: {
			AppTheme.menuLabel(text: "Buy-in", value: buyInFilterLabel)
				.accessibilityFocused($a11yFocus, equals: .buyIn)
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
	
	private func restorePendingAccessibilityFocus() {
		DispatchQueue.main.async {
			switch pendingFocusTarget {
			case .tableMenu:
				a11yFocus = .tableMin
			case .buyInMenu:
				a11yFocus = .buyIn
			case .none:
				break
			}
			pendingFocusTarget = nil
		}
	}

	private func normalizedName(_ strategy: Strategy) -> String {
		var name = strategy.name.trimmingCharacters(in: .whitespaces)
		name = String(name.drop(while: { $0 == "$" }))

		if name.lowercased().hasPrefix("the ") {
			name = String(name.dropFirst(4))
		}

		return name
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
	
	private func buildSectionedStrategies(from filteredStrategies: [Strategy]) -> [SectionKey: [Strategy]] {
		struct SortMeta {
			let normalizedName: String
			let numericPrefix: Int?
			let sectionKey: SectionKey
		}

		let sortMetaByID = Dictionary(uniqueKeysWithValues: filteredStrategies.map { strategy in
			let normalized = normalizedName(strategy)
			let first = normalized.first
			let sectionKey: SectionKey
			if let first, first.isNumber {
				sectionKey = .number
			} else if let first, first.isLetter {
				sectionKey = .letter(Character(first.uppercased()))
			} else {
				sectionKey = .number
			}

			return (
				strategy.id,
				SortMeta(
					normalizedName: normalized,
					numericPrefix: numericPrefix(of: normalized),
					sectionKey: sectionKey
				)
			)
		})

		let grouped = Dictionary(grouping: filteredStrategies) { strategy -> SectionKey in
			sortMetaByID[strategy.id]?.sectionKey ?? .number
		}

		return grouped.mapValues { group in
			group.sorted { a, b in
				let metaA = sortMetaByID[a.id]
				let metaB = sortMetaByID[b.id]
				let na = metaA?.normalizedName ?? normalizedName(a)
				let nb = metaB?.normalizedName ?? normalizedName(b)
				let numA = metaA?.numericPrefix
				let numB = metaB?.numericPrefix

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

	private func rebuildDerivedStrategies() {
		var filtered = allStrategies

		let q = searchText
			.trimmingCharacters(in: .whitespacesAndNewlines)
			.lowercased()

		if !q.isEmpty {
			filtered = filtered.filter { strategy in
				let indexed = searchNameIndex[strategy.id] ?? strategy.name.lowercased()
				return indexed.contains(q)
			}
		}

		if let f = tableMinFilter {
			filtered = filtered.filter { matchesTableMinFilter(strategy: $0, filter: f) }
		}

		if let f = buyInFilter {
			filtered = filtered.filter { matchesBuyInFilter(strategy: $0, filter: f) }
		}

		let sectioned = buildSectionedStrategies(from: filtered)
		filteredStrategiesCache = filtered
		sectionedStrategiesCache = sectioned
		sectionOrderCache = sectioned.keys.sorted()
	}

	private func rebuildSearchNameIndex() {
		searchNameIndex = Dictionary(
			uniqueKeysWithValues: allStrategies.map { strategy in
				(strategy.id, strategy.name.lowercased())
			}
		)
	}
	
	private func announceSearchResults() {
		let count = filteredStrategiesCache.count
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
