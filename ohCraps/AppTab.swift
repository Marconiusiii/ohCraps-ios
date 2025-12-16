import SwiftUI

enum AppTab: Hashable, CaseIterable {
	case strategies
	case rules
	
	var title: String {
		switch self {
		case .strategies: return "Strategies"
		case .rules: return "Rules"
		}
	}
	
	var accessibilityLabel: String {
		title
	}
}
