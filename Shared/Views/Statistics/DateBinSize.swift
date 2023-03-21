import SwiftUI

enum DateBinSize: Hashable, CaseIterable {
	case day, week, month, year
	
	var component: Calendar.Component {
		switch self {
		case .day:
			return .day
		case .week:
			return .weekOfYear
		case .month:
			return .month
		case .year:
			return .year
		}
	}
	
	var name: LocalizedStringKey {
		switch self {
		case .day:
			return "Day"
		case .week:
			return "Week"
		case .month:
			return "Month"
		case .year:
			return "Year"
		}
	}
}
