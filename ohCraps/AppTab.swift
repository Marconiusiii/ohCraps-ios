import SwiftUI

enum AppTab: Hashable, CaseIterable {
	case strategies
	case rules
	case createStrategy
	case about
	
	var title: String {
		switch self {
		case .strategies: return "Strategies"
		case .rules: return "Rules"
		case .createStrategy: return "Create Strategy"
		case .about: return "About"
		}
	}
	
	var accessibilityLabel: String {
		title
	}
}
