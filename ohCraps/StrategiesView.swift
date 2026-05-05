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
	case favorites
	case number
	case letter(Character)

	var display: String {
		switch self {
		case .favorites: return "Favorites"
		case .number: return "Numbers"
		case .letter(let c): return String(c)
		}
	}

	static func < (lhs: SectionKey, rhs: SectionKey) -> Bool {
		switch (lhs, rhs) {
		case (.favorites, _): return true
		case (_, .favorites): return false
		case (.number, .letter): return true
		case (.letter, .number): return false
		case (.number, .number): return false
		case let (.letter(a), .letter(b)): return a < b
		}
	}
}


struct StrategiesView: View {
	@Binding var hideTabBar: Bool
	@EnvironmentObject private var favStore: FavoritesStore

	@State private var allStrategies: [Strategy] = []
	@State private var isLoading = true
	@State private var filteredStrategiesCache: [Strategy] = []
	@State private var sectionedStrategiesCache: [SectionKey: [Strategy]] = [:]
	@State private var sectionOrderCache: [SectionKey] = []
	
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
	@AccessibilityFocusState private var listFocus: StratListFocus?

	private enum StratListFocus: Hashable {
		case title
		case strategy(UUID)
	}

	@State private var announceWorkItem: DispatchWorkItem?
	@State private var didFocusTitleOnLoad = false
	@State private var pendingReturnFocusID: UUID? = nil
	@State private var selectedStrategy: Strategy?

	private var searchTextField: some View {
		HStack(spacing: 8) {
			Image(systemName: "magnifyingglass")
				.foregroundColor(AppTheme.textSecondary)
				.accessibilityHidden(true)

			TextField(
				"",
				text: $searchText,
				prompt: Text("Search strategies")
					.foregroundColor(AppTheme.placeholderText)
			)
				.textFieldStyle(.plain)
				.foregroundColor(AppTheme.textPrimary)
				.focused($isSearchFocused)
				.submitLabel(.search)
				.accessibilityLabel("Search Strategies")
				.accessibilityValue(searchText)
		}
		.padding(.horizontal, 12)
		.padding(.vertical, 10)
		.background(AppTheme.controlFill)
		.overlay(
			RoundedRectangle(cornerRadius: 8, style: .continuous)
				.stroke(AppTheme.borderColor, lineWidth: 1)
		)
		.overlay(
			RoundedRectangle(cornerRadius: 8, style: .continuous)
				.stroke(AppTheme.feltLineSoft, lineWidth: 1)
				.padding(2)
		)
		.cornerRadius(8)
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
					.accessibilityFocused($listFocus, equals: .title)
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
					rebuildDerivedStrategies()
					isLoading = false
				}
			}
			.onChange(of: allStrategies) {
				rebuildDerivedStrategies()
			}
			.onChange(of: searchText) {
				rebuildDerivedStrategies()
			}
			.onChange(of: tableMinFilter) {
				rebuildDerivedStrategies()
			}
			.onChange(of: buyInFilter) {
				rebuildDerivedStrategies()
			}
			.onChange(of: favStore.favoriteIDs) {
				rebuildDerivedStrategies()
			}
			.onChange(of: isLoading) { _, loading in
				guard !loading, !didFocusTitleOnLoad else { return }
				didFocusTitleOnLoad = true
				focusTitleAfterLoad()
			}
			.navigationDestination(item: $selectedStrategy) { strategy in
				StrategyDetailView(
					strategy: strategy,
					hideTabBar: $hideTabBar,
					keepBarHiddenOnClose: .constant(false),
					onFavToggled: { id in
						pendingReturnFocusID = id
					}
				)
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
				.onChange(of: tableMinFilter) {
					restorePendingAccessibilityFocus()
				}
				.onChange(of: buyInFilter) {
					restorePendingAccessibilityFocus()
				}

			ScrollViewReader { proxy in
				List {
					ForEach(sectionOrderCache, id: \.self) { section in
						if let items = sectionedStrategiesCache[section], !items.isEmpty {
							Section {
								ForEach(items) { strategy in
									Button {
										pendingReturnFocusID = strategy.id
										listFocus = nil
										selectedStrategy = strategy
									} label: {
								Text(strategy.name)
									.foregroundColor(AppTheme.textPrimary)
									.fixedSize(horizontal: false, vertical: true)
								}
								.buttonStyle(.plain)
								.contentShape(Rectangle())
								.id(strategy.id)
								.listRowBackground(AppTheme.feltBlackInk.opacity(0.72))
								.accessibilityFocused($listFocus, equals: .strategy(strategy.id))
							}
						} header: {
							Text(section.display)
								.font(AppTheme.sectionHeader)
								.foregroundColor(section == .favorites ? AppTheme.feltRed : AppTheme.textSecondary)
								.accessibilityAddTraits(.isHeader)
								.accessibilityIdentifier(sectionID(for: section))
						}
						}
					}
				}
				.listStyle(.plain)
				.scrollContentBackground(.hidden)
				.background(Color.clear)
				.onChange(of: selectedStrategy) { _, strategy in
					guard strategy == nil, let id = pendingReturnFocusID else { return }
					pendingReturnFocusID = nil
					restoreRowFocus(id, with: proxy)
				}
			}
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
		.onChange(of: searchText) {
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
		.foregroundColor(AppTheme.textSecondary)
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
		.overlay(alignment: .top) {
			Rectangle()
				.fill(AppTheme.feltLineSoft)
				.frame(height: 1)
		}
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

	private func buildSectionedStrategies(from filteredStrategies: [Strategy]) -> [SectionKey: [Strategy]] {
		let sectionByID = Dictionary(uniqueKeysWithValues: filteredStrategies.map { strategy in
			let first = strategy.sortName.first
			let sectionKey: SectionKey
			if let first, first.isNumber {
				sectionKey = .number
			} else if let first, first.isLetter {
				sectionKey = .letter(Character(first.uppercased()))
			} else {
				sectionKey = .number
			}

			return (strategy.id, sectionKey)
		})

		let grouped = Dictionary(grouping: filteredStrategies) { strategy -> SectionKey in
			sectionByID[strategy.id] ?? .number
		}

		return grouped.mapValues { group in
			group.sorted { a, b in
				switch (a.sortNum, b.sortNum) {
				case let (x?, y?):
					if x != y { return x < y }
					return a.sortName.localizedCaseInsensitiveCompare(b.sortName) == .orderedAscending
				case (.some, .none):
					return true
				case (.none, .some):
					return false
				case (.none, .none):
					return a.sortName.localizedCaseInsensitiveCompare(b.sortName) == .orderedAscending
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
				strategy.searchName.contains(q)
			}
		}

		if let f = tableMinFilter {
			filtered = filtered.filter { matchesTableMinFilter(strategy: $0, filter: f) }
		}

		if let f = buyInFilter {
			filtered = filtered.filter { matchesBuyInFilter(strategy: $0, filter: f) }
		}

		let favIDs = favStore.favoriteIDs
		let favs = filtered
			.filter { favIDs.contains($0.id) }
			.sorted { $0.sortName.localizedCaseInsensitiveCompare($1.sortName) == .orderedAscending }
		let rest = filtered.filter { !favIDs.contains($0.id) }

		var sectioned = buildSectionedStrategies(from: rest)
		if !favs.isEmpty {
			sectioned[.favorites] = favs
		}

		filteredStrategiesCache = filtered
		sectionedStrategiesCache = sectioned
		sectionOrderCache = sectioned.keys.sorted()
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

	private func focusTitleAfterLoad() {
		Task { @MainActor in
			listFocus = nil
			await Task.yield()
			await Task.yield()
			listFocus = .title
		}
	}

	private func restoreRowFocus(_ id: UUID, with proxy: ScrollViewProxy) {
		Task { @MainActor in
			listFocus = nil
			proxy.scrollTo(id, anchor: .center)
			await Task.yield()
			await Task.yield()
			listFocus = .strategy(id)
		}
	}

	private func sectionID(for key: SectionKey) -> String {
		switch key {
		case .favorites:
			return "section-favorites"
		case .number:
			return "section-number"
		case .letter(let c):
			return "section-\(c)"
		}
	}


}
