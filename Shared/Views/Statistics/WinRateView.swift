import SwiftUI
import ValorantAPI
import Charts
import Collections
import CGeometry

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
			Section(header: Text("Over Time", comment: "Win Rate Stats: section")) {
				chartOverTime()
			}
			
			Section(header: Text("By Map", comment: "Win Rate Stats: section")) {
				byMap()
			}
			
			Section(header: Text("Rounds by Side", comment: "Win Rate Stats: section")) {
				roundsBySide()
			}
			
			Section(header: Text("Rounds by Loadout Delta", comment: "Win Rate Stats: section")) {
				roundsByLoadoutDelta()
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
	
	@State var timeGrouping = DateBinSize.day
	
	@ViewBuilder
	func chartOverTime() -> some View {
		ChartOverTime(winRate: winRate, stacking: stacking, timeGrouping: timeGrouping)
			.chartYAxis { maybePercentageLabels() }
			.aligningListRowSeparator()
			.padding(.vertical)
		
		Picker(
			String(localized: "Group by", comment: "Stats: date grouping size picker"),
			selection: $timeGrouping
		) {
			ForEach(DateBinSize.allCases) { size in
				Text(size.name).tag(size)
			}
		}
	}
	
	@State private var startingSideFilter: Side?
	
	@ScaledMetric(relativeTo: .callout)
	private var mapRowHeight = 35
	
	@ViewBuilder
	func byMap() -> some View {
		Group {
			let data: [MapID: Tally] = startingSideFilter.map { winRate.byStartingSide[$0] ?? [:] } ?? winRate.byMap
			winRateByMap(entries: [("All Maps", data.values.reduce(into: .zero, +=) )])
				.chartLegend(.hidden)
			
			let maps = winRate.byMap.keys
			winRateByMap(entries: maps.map { map in (name(for: map), data[map] ?? .zero) })
				.chartYScale(domain: .automatic(dataType: String.self) { $0.sort() })
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
		.chartXAxis { maybePercentageLabels() }
		.chartYAxis { boldLabels() }
		.aligningListRowSeparator()
		
		VStack(spacing: 8) {
			Text("Starting Side:", comment: "Win Rate Stats")
				.font(.callout)
				.frame(maxWidth: .infinity, alignment: .leading)
			Picker(
				String(localized: "Starting Side", comment: "Win Rate Stats: accessibility label"),
				selection: $startingSideFilter
			) {
				Text("Total", comment: "Win Rate Stats: side name").tag(nil as Side?)
				Text("Attacking", comment: "Win Rate Stats: side name").tag(.attacking as Side?)
				Text("Defending", comment: "Win Rate Stats: side name").tag(.defending as Side?)
			}
			.pickerStyle(.segmented)
			
			Text("Filtering by starting side will exclude any matches in single-round modes like Deathmatch, Escalation, etc.")
				.font(.footnote)
				.foregroundStyle(.secondary)
				.frame(maxWidth: .infinity, alignment: .leading)
		}
	}
	
	private func winRateByMap(entries: [(map: String, tally: Tally)]) -> some View {
		Chart(entries, id: \.map) { map, tally in
			marks(for: tally, y: .value("Map", map))
		}
		.chartPlotStyle { $0
			.frame(height: .init(entries.count) * mapRowHeight)
		}
		.chartOverlay { chart in
			ForEach(entries, id: \.map) { map, tally in
				chart.rowLabel(y: map) {
					Group {
						if tally.total > 0 {
							Text(tally.winFraction, format: .precisePercent)
						} else {
							Text("No data", comment: "Win Rate Stats: by map")
						}
					}
					.padding(.horizontal, 0.15 * mapRowHeight)
				}
			}
		}
	}
	
	@ScaledMetric(relativeTo: .caption2)
	private var sideRowHeight = 25
	
	@ViewBuilder
	func roundsBySide() -> some View {
		Grid(verticalSpacing: 12) {
			let total: [Side: Tally] = winRate.roundsBySide.values
				.reduce(into: [:]) { $0.merge($1, uniquingKeysWith: +) }
			GridRow(alignment: .top) {
				// tried to use an alignment guide for this, but it doesn't propagate out of .chartOverlay()
				Text("All Maps")
					.font(.callout.weight(.medium))
					.gridColumnAlignment(.leading)
					.frame(height: 0) // to "anchor" offset to center instead of top edge
					.offset(y: sideRowHeight)
				
				roundsBySide(total)
					.chartXAxis { maybePercentageLabels() }
			}
			
			Divider()
			
			let maps = winRate.roundsBySide.sorted { name(for: $0.key) }
			ForEach(maps, id: \.key) { map, bySide in
				GridRow(alignment: .top) {
					Text(name(for: map))
						.font(.callout.weight(.medium))
						.gridColumnAlignment(.leading)
						.frame(height: 0) // to "anchor" offset to center instead of top edge
						.offset(y: sideRowHeight)
					
					roundsBySide(bySide)
						.chartXScale(domain: .automatic(dataType: Int.self) { domain in
							if !shouldNormalize {
								let max = winRate.roundsBySide.values
									.lazy
									.flatMap(\.values)
									.map(\.total)
									.max() ?? 0
								domain.append(max) // consistent domain across charts
							}
						})
						.chartXAxis {
							AxisMarks { value in
								AxisGridLine()
								AxisTick()
								if map == maps.last!.key {
									AxisValueLabel {
										let value = value.as(Int.self)!
										if shouldNormalize {
											Text("\(value)%")
										} else {
											Text("\(value)")
										}
									}
								}
							}
						}
				}
			}
		}
	}
	
	private func sortedMaps(_ keys: some Sequence<MapID?>) -> [MapID?] {
		keys.sorted { $0.map(name(for:)) ?? "" }
	}
	
	private func roundsBySide(_ bySide: [Side: Tally]) -> some View {
		Chart {
			ForEach(Side.allCases, id: \.self) { side in
				let tally = bySide[side] ?? .zero // always show both sides (one could be zero if there's only a single surrendered match)
				BarMark(x: .value("Count", tally.wins), y: .value("Side", side.name), stacking: stacking)
					.foregroundStyle(by: .value("Outcome", MatchOutcomeKey.wins))
				BarMark(x: .value("Count", tally.losses), y: .value("Side", side.name), stacking: stacking)
					.foregroundStyle(by: .value("Outcome", MatchOutcomeKey.losses))
			}
		}
		.chartOverlay { chart in
			ForEach(Side.allCases, id: \.self) { side in
				chart.rowLabel(y: side.name) {
					Group {
						if let tally = bySide[side] {
							Text(tally.winFraction, format: .precisePercent)
						} else {
							Text("No data")
						}
					}
					.padding(.horizontal, 0.1 * sideRowHeight)
				}
			}
		}
		.chartPlotStyle { $0
			.frame(height: sideRowHeight * 2)
		}
		.chartYScale(domain: .automatic(dataType: String.self) { $0.sort() })
		.chartYAxis { AxisMarks(preset: .aligned) }
		.chartLegend(.hidden)
		.chartForegroundStyleScale(Tally.foregroundStyleScale)
	}
	
	@ViewBuilder
	func roundsByLoadoutDelta() -> some View {
		RoundsByLoadoutDeltaChart(winRate: winRate, stacking: stacking)
			.padding(.top)
			.aligningListRowSeparator()
		
		Text("Loadout Delta is computed as the difference between the average loadout value of players on each team. For example, a loadout delta of +1000 means your team's loadouts were an average of 1000 credits more valuable than the enemy team's in that round.")
			.font(.footnote)
			.foregroundStyle(.secondary)
	}
	
	private func boldLabels() -> some AxisContent {
		AxisMarks(preset: .aligned) { value in
			AxisValueLabel {
				Text(value.as(String.self)!)
					.font(.callout.weight(.medium))
					.foregroundColor(.primary)
			}
		}
	}
	
	private func maybePercentageLabels() -> some AxisContent {
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
	
	private func marks<Y: Plottable>(for tally: Tally, y: PlottableValue<Y>) -> some ChartContent {
		ForEach(tally.data(), id: \.key) { key, count in
			BarMark(x: .value("Count", count), y: y, stacking: stacking)
				.foregroundStyle(by: .value("Outcome", key))
		}
	}
	
	func value(for map: MapID) -> PlottableValue<String> {
		.value("Map", name(for: map))
	}
	
	func name(for map: MapID) -> String {
		assets?.maps[map]?.displayName ?? map.rawValue
	}
	
	struct ChartOverTime: View {
		var winRate: Statistics.WinRate
		var stacking: MarkStackingMethod
		var timeGrouping: DateBinSize
		
		var body: some View {
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
					.foregroundStyle(by: .value("Outcome", data.entry.key))
				}
			}
			.chartForegroundStyleScale(Tally.foregroundStyleScale)
		}
	}
}

@available(iOS 16.0, *)
extension WinRateView {
	init(statistics: Statistics) {
		self.init(
			statistics: statistics,
			timeGrouping: .smallestThatFits(statistics.winRate.byDay.keys)
		)
	}
	
	static func overview(statistics: Statistics) -> ChartOverTime? {
		.init(
			winRate: statistics.winRate,
			stacking: .standard,
			timeGrouping: .smallestThatFits(statistics.winRate.byDay.keys)
		)
	}
}

@available(iOS 16.0, *)
private struct RoundsByLoadoutDeltaChart: View {
	var winRate: Statistics.WinRate
	var stacking: MarkStackingMethod
	
	@State private var focusedDelta: Range<Int>?
	
	var body: some View {
		Chart {
			let data: [(delta: Int, entry: Tally.Entry)] = winRate.roundsByLoadoutDelta
				.map { delta, tally in tally.data().map { (delta, $0) } }
				.flatTransposed()
			
			ForEach(data, id: \.delta) { delta, entry in
				BarMark(
					x: .value("Loadout Delta", binRange(forDelta: delta)),
					y: .value("Count", entry.count),
					stacking: stacking
				)
				.foregroundStyle(by: .value("Outcome", entry.key))
				.opacity(focusedDelta.map { $0.contains(delta) } == false ? 0.5 : 1)
			}
		}
		.chartForegroundStyleScale(Tally.foregroundStyleScale)
		.chartXAxisLabel(String(localized: "Value Difference (credits)", comment: "Win Rate Stats by Loadout Delta"), alignment: .center)
		.chartPlotStyle { $0.frame(height: 200).clipped() }
		.chartLegend(.hidden)
		.withChartXGesture { focusedDelta = $0.map(binRange(forDelta:)) }
		.overlay(alignment: .topLeading) {
			focusedValueInfo()
				.padding(-8)
		}
	}
	
	@ViewBuilder
	private func focusedValueInfo() -> some View {
		if let focusedDelta {
			let tally = winRate.roundsByLoadoutDelta
				.lazy
				.filter { focusedDelta.contains($0.key) }
				.map(\.value)
				.reduce(into: .zero, +=)
			
			VStack(alignment: .leading) {
				Text("\(focusedDelta.lowerBound) to \(focusedDelta.upperBound) credits", comment: "Win Rate Stats by Loadout Delta: focused value (drag on graph)")
					.font(.footnote)
					.foregroundStyle(.secondary)
				HStack {
					if tally != .zero {
						Text("\(tally.winFraction, format: .precisePercent) won", comment: "Win Rate Stats by Loadout Delta: focused value (drag on graph); placeholder is replaced by the percentage of rounds won, e.g. '57.3% won'.")
						Text("(\(tally.wins) – \(tally.losses))", comment: "Win Rate Stats by Loadout Delta: focused value (drag on graph)")
							.foregroundStyle(.secondary)
					} else {
						Text("No data", comment: "Win Rate Stats by Loadout Delta: focused value (drag on graph)")
							.foregroundStyle(.secondary)
					}
				}
				.font(.callout.bold())
			}
			.monospacedDigit()
			.padding(8)
			.background(.regularMaterial)
			.cornerRadius(8)
		}
	}
	
	private let deltaBinSize = 200
	private func binRange(forDelta delta: Int) -> Range<Int> {
		let offset = deltaBinSize / 2
		let bin = (Double(delta + offset) / Double(deltaBinSize)).rounded(.down)
		let midpoint = Int(bin) * deltaBinSize
		return midpoint - offset ..< midpoint + offset
	}
}

@available(iOS 16.0, *)
private extension ChartProxy {
	func rowLabel<Label: View>(
		y: some Plottable,
		@ViewBuilder label: @escaping () -> Label
	) -> some View {
		GeometryReader { geometry in
			if let yRange = positionRange(forY: y) {
				let plotArea = geometry[plotAreaFrame]
				label()
					.font(.caption2)
					.monospacedDigit()
					.opacity(0.75)
					.shadow(color: Color(.systemBackground).opacity(0.5), radius: 1, y: 1)
					.blendMode(.hardLight)
					.frame(width: plotArea.width, height: yRange.upperBound - yRange.lowerBound, alignment: .leading)
					.position(x: plotArea.midX, y: (yRange.lowerBound + yRange.upperBound) / 2)
			}
		}
	}
}

@available(iOS 16.0, *)
private extension View {
	func withChartXGesture<Value: Plottable>(onPan: @escaping (Value?) -> Void) -> some View {
		chartOverlay { chart in
			GeometryReader { geometry in
				Color.clear.contentShape(Rectangle()).gesture(
					DragGesture()
						.onChanged { gesture in
							let plotLocation = gesture.location - geometry[chart.plotAreaFrame].origin
							onPan(chart.value(atX: plotLocation.dx)!)
						}
						.onEnded { _ in onPan(nil) }
				)
			}
		}
	}
}

extension Side {
	var name: String {
		switch self {
		case .attacking:
			return String(localized: "Attacking", comment: "Win Rate Stats: side name")
		case .defending:
			return String(localized: "Defending", comment: "Win Rate Stats: side name")
		}
	}
}

@available(iOS 16.0, *)
private extension Tally {
	typealias Entry = (key: MatchOutcomeKey, count: Int)
	
	var winFraction: Double {
		.init(wins) / .init(total)
	}
	
	func data() -> [Entry] {
		[
			(.wins, wins),
			(.draws, draws),
			(.losses, losses),
		]
	}
	
	static let foregroundStyleScale: KeyValuePairs<MatchOutcomeKey, Color> = [
		.wins: .valorantBlue,
		.draws: .valorantSelf,
		.losses: .valorantRed,
	]
}

@available(iOS 16.0, *)
private enum MatchOutcomeKey: Plottable {
	case wins, draws, losses
	
	init?(primitivePlottable: String) {
		fatalError()
	}
	
	var primitivePlottable: String {
		switch self {
		case .wins:
			return String(localized: "Wins", comment: "Win Rate Stats: chart legend")
		case .draws:
			return String(localized: "Draws", comment: "Win Rate Stats: chart legend")
		case .losses:
			return String(localized: "Losses", comment: "Win Rate Stats: chart legend")
		}
	}
}

#if DEBUG
@available(iOS 16.0, *)
struct WinRateView_Previews: PreviewProvider {
	static var previews: some View {
		WinRateView(statistics: PreviewData.statistics, timeGrouping: .year)
			.withToolbar()
		WinRateView(statistics: PreviewData.statistics, timeGrouping: .year)
			.withToolbar()
			.environment(\.locale, .init(identifier: "de-DE"))
		WinRateView(statistics: .init(userID: PreviewData.userID, matches: [PreviewData.surrenderedMatch]))
			.withToolbar()
	}
}
#endif
