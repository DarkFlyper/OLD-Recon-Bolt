import SwiftUI

enum DateBinSize: Hashable, Identifiable, CaseIterable {
	case day, week, month, year
	
	var id: Self { self }
	
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
	
	func requiredBins(for range: Range<Date>) -> Int {
		Calendar.current
			.dateComponents([component], from: range.lowerBound, to: range.upperBound)
			.value(for: component)!
	}
	
	static func smallestThatFits(_ range: Range<Date>, maxBins: Int = 30) -> Self {
		allCases.first { $0.requiredBins(for: range) <= maxBins } ?? .year
	}
	
	static func smallestThatFits(_ dates: some Sequence<Date>, maxBins: Int = 30) -> Self {
		guard let (min, max) = dates.minAndMax() else { return .day }
		return smallestThatFits(min..<max, maxBins: maxBins)
	}
}
