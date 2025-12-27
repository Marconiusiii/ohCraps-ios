import SwiftUI

enum AppTab: Hashable, CaseIterable {
	case strategies
	case rules
	case about
	
	var title: String {
		switch self {
		case .strategies: return "Strategies"
		case .rules: return "Rules"
		case .about: return "About"
		}
	}
	
	var accessibilityLabel: String {
		title
	}
}
