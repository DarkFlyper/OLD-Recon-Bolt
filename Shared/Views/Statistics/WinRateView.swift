import SwiftUI
import ValorantAPI
import Charts
import Collections

private typealias WinRate = Statistics.WinRate
private typealias Tally = WinRate.Tally
private typealias Side = WinRate.Side

@available(iOS 16.0, *)
struct WinRateView: View {
	var statistics: Statistics
	var winRate: Statistics.WinRate { statistics.winRate }
	
	@AppStorage("WinRateView.shouldNormalize")
	var shouldNormalize = false
	
	@Environment(\.assets) private var assets
	
	var stacking: MarkStackingMethod {
		shouldNormalize ? .normalized : .standard
	}
	
    var body: some View {
		List {
			Section("Over Time") {
				chartOverTime()
			}
			
			Section("By Map") {
				byMap()
			}
		}
		.toolbar {
			ToolbarItemGroup(placement: .bottomBar) {
				Toggle("Normalize Charts", isOn: $shouldNormalize.animation(.easeInOut))
					.padding(.vertical)
			}
		}
		.navigationTitle("Win Rate")
    }
	
	@State var timeGrouping = BucketSize.day
	
	@ViewBuilder
	func chartOverTime() -> some View {
		Chart {
			// transposing the data like this means we can let Charts group the data automatically, stacking up all outcomes of one type before any of the next type
			let data: [(day: Date, entry: Tally.Entry)] = winRate.byDay
				.map { day, tally in tally.data().map { (day, $0) } }
				.flatTransposed()
			
			ForEach(data.indexed(), id: \.index) { index, data in
				BarMark(
					x: .value("Day", data.day, unit: timeGrouping.component),
					y: .value("Count", data.entry.count),
					stacking: stacking
				)
				.foregroundStyle(by: .value("Outcome", data.entry.name))
			}
			
			if shouldNormalize {
				RuleMark(y: .value("Count", 50))
					.lineStyle(.init(lineWidth: 1, dash: [4, 2]))
					.foregroundStyle(Color.secondary)
			}
		}
		.chartForegroundStyleScale(Tally.foregroundStyleScale)
		.chartYAxis { maybePercentageLabels(showTicks: false) }
		.aligningListRowSeparator()
		.padding(.vertical)
		
		Picker("Group by", selection: $timeGrouping) {
			ForEach(BucketSize.allCases, id: \.self) { size in
				Text(size.name).tag(size)
			}
		}
	}
	
	@State private var startingSideFilter: Side?
	
	@ScaledMetric(relativeTo: .callout)
	private var mapRowHeight = 45
	
	@ViewBuilder
	func byMap() -> some View {
		Chart {
			if let startingSideFilter {
				ForEach(Array(winRate.byStartingSide), id: \.key) { map, bySide in
					let tally = bySide[startingSideFilter] ?? .zero
					mapEntry(map: map, tally: tally)
				}
			} else {
				ForEach(Array(winRate.byMap), id: \.key, content: mapEntry)
			}
		}
		.chartForegroundStyleScale(Tally.foregroundStyleScale)
		.chartXScale(domain: .automatic(dataType: Int.self) { domain in
			if !shouldNormalize, startingSideFilter != nil {
				let max = winRate.byStartingSide.values
					.lazy
					.flatMap(\.values)
					.map(\.total)
					.max() ?? 0
				domain.append(max) // consistent scale across views
			}
		})
		.chartYScale(domain: .automatic(dataType: String.self) { domain in
			domain.sort()
		})
		.chartPlotStyle { $0
			.frame(height: mapRowHeight * .init(winRate.byMap.count))
		}
		.chartXAxis { maybePercentageLabels(showTicks: true) }
		.chartYAxis { boldLabels() }
		.aligningListRowSeparator()
		
		VStack(spacing: 8) {
			Text("Starting Side:")
				.font(.callout)
				.frame(maxWidth: .infinity, alignment: .leading)
			Picker("Starting Side", selection: $startingSideFilter) {
				Text("Total").tag(nil as Side?)
				Text("Attacking").tag(.attacking as Side?)
				Text("Defending").tag(.defending as Side?)
			}
			.pickerStyle(.segmented)
			
			Text("Filtering by starting side will exclude any matches in single-round modes like Deathmatch, Escalation, etc.")
				.font(.footnote)
				.foregroundStyle(.secondary)
				.frame(maxWidth: .infinity, alignment: .leading)
		}
	}
	
	private func boldLabels() -> some AxisContent {
		AxisMarks { value in
			AxisValueLabel {
				Text(value.as(String.self)!)
					.font(.callout.weight(.medium))
					.foregroundColor(.primary)
			}
		}
	}
	
	private func maybePercentageLabels(showTicks: Bool) -> some AxisContent {
		AxisMarks { value in
			AxisValueLabel {
				let value = value.as(Int.self)!
				if shouldNormalize {
					Text("\(value)%")
				} else {
					Text("\(value)")
				}
			}
			AxisGridLine()
			AxisTick()
		}
	}
	
	private func mapEntry(map: MapID, tally: Tally) -> some ChartContent {
		ForEach(tally.data(), id: \.name) { name, count in
			BarMark(
				x: .value("Count", count),
				y: value(for: map),
				stacking: stacking
			)
			.foregroundStyle(by: .value("Outcome", name))
		}
	}
	
	func value(for map: MapID) -> PlottableValue<String> {
		.value("Map", assets?.maps[map]?.displayName ?? map.rawValue)
	}
}

enum BucketSize: Hashable, CaseIterable {
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

extension Side {
	var name: String { // TODO: localize!
		switch self {
		case .attacking:
			return "Attacking"
		case .defending:
			return "Defending"
		}
	}
}

private extension Tally {
	typealias Entry = (name: String, count: Int)
	
	func data() -> [Entry] { // TODO: localize!
		[
			("Wins", wins),
			("Draws", draws),
			("Losses", losses),
		]
	}
	
	static let foregroundStyleScale: KeyValuePairs = [ // TODO: localize!
		"Wins": Color.valorantBlue,
		"Draws": Color.valorantSelf,
		"Losses": Color.valorantRed,
	]
}

#if DEBUG
@available(iOS 16.0, *)
struct WinRateView_Previews: PreviewProvider {
    static var previews: some View {
		WinRateView(statistics: PreviewData.statistics, timeGrouping: .year)
			.withToolbar()
    }
}
#endif
