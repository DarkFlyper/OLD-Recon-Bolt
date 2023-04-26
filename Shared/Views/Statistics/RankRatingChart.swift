import SwiftUI
import ValorantAPI
import Collections
import Charts
import HandyOperators

@available(iOS 16.0, *)
struct RankRatingChart: View {
	var matches: [CompetitiveUpdate]
	
	@State var maxCount = 20
	
	@ScaledMetric(relativeTo: .caption2)
	private var chartPadding = 20
	let expandButtonWidth: CGFloat = 32 // space for "show more" button
	
	@Environment(\.seasons) private var seasons
	
    var body: some View {
		let ranked = matches.lazy.filter(\.isRanked)
		let changes = ranked.prefix(maxCount).reversed() as Array
		let span = changes.lazy.map(\.tierAfterUpdate).minAndMax().map { $0.max - $0.min } ?? 0
#if WIDGETS
		scrollableContent(changes: changes)
#else
		GeometryReader { geometry in
			ScrollView(.horizontal) {
				scrollableContent(changes: changes)
					.frame(width: max(12 * CGFloat(changes.count), geometry.size.width))
					.scaleEffect(x: -1, y: 1, anchor: .center) // unflip from below
			}
			.scaleEffect(x: -1, y: 1, anchor: .center) // flip to start at trailing edge
			.scrollBounceBasedOnSize()
		}
		.frame(height: (CGFloat(span) * 150).clamped(to: 150...300))
#endif
    }
	
	@ViewBuilder
	func scrollableContent(changes: [CompetitiveUpdate]) -> some View {
		if let seasons = seasons {
			let data = ChartData(matches: changes, seasons: seasons)
#if WIDGETS
			chart(from: data, canExpand: false)
#else
			ZStack(alignment: .leading) {
				let hiddenCount = matches.count(where: \.isRanked) - changes.count
				
				chart(from: data, canExpand: hiddenCount > 0)
				
				if hiddenCount > 0 {
					Button {
						maxCount = .max
					} label: {
						Label("Show all matches", systemImage: "ellipsis")
					}
					.labelStyle(.iconOnly)
					.padding(4)
					.background {
						Circle()
							.fill(prettyDarkening.opacity(0.15))
							.aspectRatio(1, contentMode: .fill)
					}
					.foregroundColor(.white)
					.padding(8)
					.fixedSize()
					.frame(width: chartPadding + expandButtonWidth)
				}
			}
#endif
		} else {
			Text("Missing season data!")
				.foregroundStyle(.secondary)
				.frame(maxHeight: .infinity)
		}
	}
	
	private func chart(from data: ChartData, canExpand: Bool) -> some View {
		Chart(data.entries) { entry in
			LineMark(
				x: .value("Match", entry.index),
				y: .value("ELO", entry.elo),
				series: .value("Series", entry.series)
			)
			.foregroundStyle(Color.white)
			.symbol(.circle)
		}
		.chartPlotStyle { $0.opacity(0.5).blendMode(.plusLighter) }
		.chartXAxis(.hidden)
		.chartYAxis {
			AxisMarks(values: .stride(by: 100)) {
				AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
					.foregroundStyle(prettyDarkening.opacity(0.1))
			}
		}
		.chartXScale(range: .plotDimension(
			startPadding: chartPadding + (canExpand ? expandButtonWidth : 0),
			endPadding: chartPadding
		))
		.chartYScale(
			domain: .automatic(includesZero: false),
			range: .plotDimension(padding: chartPadding)
		)
		.chartBackground { chart in
			GeometryReader { geometry in
				ChartBackground(
					chart: chart,
					plotArea: geometry[chart.plotAreaFrame],
					data: data,
					labelHeight: chartPadding
				)
			}
		}
	}
	
	private struct ChartData {
		var matches: [CompetitiveUpdate]
		var seasons: SeasonCollection.Accessor
		var tierCollections: [Act.WithTiers]
		var entries: [Entry] = []
		
		init(matches: [CompetitiveUpdate], seasons: SeasonCollection.Accessor) {
			self.matches = matches
			self.seasons = seasons
			let timeRange = matches.map(\.startTime).minAndMax().map(...)
			tierCollections = timeRange.map(seasons.tierCollections(relevantTo:)) ?? []
			
			var acts = tierCollections[...]
			var currentAct: Act.WithTiers?
			var currentAbsoluteThreshold: Int?
			var lastUpdate: CompetitiveUpdate? // used to determine when to start a new line (discontiguous data or season change)
			var series = 0
			for (index, match) in matches.enumerated() {
				while currentAct?.act.timeSpan.contains(match.startTime) != true, let next = acts.popFirst() {
					currentAct = next // no data on acts this late, apparently
					currentAbsoluteThreshold = next.act.usesAbsoluteRRForImmortalPlus
					? next.tiers.lowestImmortalPlusTier() : nil
				}
				
				if lastUpdate.map(match.isContiguous(from:)) != true {
					series += 1 // start new line
				}
				
				let elo: Int
				if let currentAbsoluteThreshold, match.tierAfterUpdate >= currentAbsoluteThreshold {
					elo = currentAbsoluteThreshold * 100 + match.tierProgressAfterUpdate
				} else {
					elo = match.tierAfterUpdate * 100 + match.tierProgressAfterUpdate
				}
				
				entries.append(.init(id: match.id, index: index, elo: elo, series: series))
				lastUpdate = match
			}
		}
		
		struct Entry: Identifiable {
			var id: Match.ID
			var index: Int
			var elo: Int
			var series: Int
		}
	}
	
	private struct ChartBackground: View {
		var tiers: [TierBackground] = []
		var seasonSpans: [(act: Act, area: CGRect)] = []
		var labelHeight: CGFloat
		
		init(chart: ChartProxy, plotArea: CGRect, data: ChartData, labelHeight: CGFloat) {
			self.labelHeight = labelHeight
			
			let tierSpacing = chart.position(forY: 0)! - chart.position(forY: 100)!
			
			let matches = data.matches
			for (index, (act, tiers)) in data.tierCollections.enumerated() {
				let startX = matches.firstIndex { act.timeSpan.contains($0.startTime) }
				guard let startX else { continue } // no match played in this act
				let endX = matches.suffix(from: startX).firstIndex { !act.timeSpan.contains($0.startTime) } ?? matches.endIndex
				let leading = index == 0 ? 0 : chart.position(forX: Double(startX) - 0.5)!
				let isLast = index == data.tierCollections.count - 1
				let trailing = isLast ? plotArea.width : chart.position(forX: Double(endX) - 0.5)!
				let width = trailing - leading
				
				seasonSpans.append((act, CGRect(
					x: leading, y: plotArea.minY,
					width: width, height: plotArea.height
				)))
				
				let absoluteThreshold = act.usesAbsoluteRRForImmortalPlus ? tiers.lowestImmortalPlusTier() : nil
				
				let tiers = tiers.tiers.values.sorted(on: \.number)
				for (index, tier) in tiers.enumerated() {
					let representsImmortalPlus = tier.number == absoluteThreshold
					let bottom = chart.position(forY: tier.number * 100)!
					let nextBottom = representsImmortalPlus ? nil : tiers.elementIfValid(at: index + 1)
					let top = nextBottom.map { chart.position(forY: $0.number * 100)! } ?? min(0, bottom)
					let minY = top.clamped(to: 0...plotArea.height)
					let maxY = bottom.clamped(to: 0...plotArea.height)
					if minY != maxY { // wouldn't be visible otherwise
						self.tiers.append(TierBackground(
							tier: representsImmortalPlus ? nil : tier,
							frame: CGRect(
								x: plotArea.minX + leading,
								y: plotArea.minY + minY,
								width: width,
								height: maxY - minY
							),
							tierSpacing: tierSpacing
						))
					}
					if representsImmortalPlus { break } // higher ranks already represented
				}
			}
		}
		
		var body: some View {
			ForEach(tiers.indexed(), id: \.index, content: \.element)
			ForEach(seasonSpans.indexed(), id: \.index) { _, span in
				Color.clear
					.frame(width: span.area.width, height: span.area.height)
					.overlay(alignment: .bottom) {
						ViewThatFits {
							Text(span.act.name)
								.font(.caption2)
								.fixedSize()
								.padding(.horizontal) // looks neater, and would otherwise intersect widget corners
								.frame(height: labelHeight)
								.foregroundStyle(prettyDarkening.opacity(0.3))
							
							Color.clear // else nothing
						}
					}
					.offset(.init(span.area.origin))
			}
		}
		
		struct TierBackground: View {
			var tier: CompetitiveTier? // nil to represent immortal+ as one
			var frame: CGRect
			var tierSpacing: CGFloat // height for 100rr
			
			var body: some View {
				fill
					.overlay {
						if frame.height >= tierSpacing - 1e-3 { // never show in the vertical margins (tolerance for FP imprecision)
							ViewThatFits {
								tier?.icon?.view()
									.frame(width: 24)
									.padding(2)
									.padding(.horizontal, 4)
									.shadow(color: .black.opacity(0.2), radius: 1, y: 1)
								
								Color.clear // else nothing
							}
						}
					}
					.overlay(alignment: .leading) {
						Line()
							.stroke(style: .init(lineWidth: 1, dash: [2, 1]))
							.frame(width: 10) // zero width here would hide it
							.frame(width: 0) // align as if zero width
							.foregroundStyle(prettyDarkening.opacity(0.2))
					}
					.frame(width: frame.width, height: frame.height)
					.offset(CGSize(frame.origin))
			}
			
			private static let radiant = Color(uiColor: #colorLiteral(red: 1, green: 0.9294117647, blue: 0.6666666667, alpha: 1))
			private static let immortal = Color(uiColor: #colorLiteral(red: 1, green: 0.3333333333, blue: 0.3176470588, alpha: 1))
			
			@ViewBuilder
			var fill: some View {
				if let tier {
					tier.backgroundColor
				} else {
					LinearGradient(colors: [Self.immortal, Self.radiant], startPoint: .bottom, endPoint: .top)
						.frame(minHeight: 4.5 * tierSpacing) // around 450 rr is the threshold for radiant in most regions, no i'm not gonna make this region-dependent lol
						.frame(height: frame.height, alignment: .bottom)
				}
			}
		}
	}
}

private extension View {
	@ViewBuilder
	func scrollBounceBasedOnSize() -> some View {
		if #available(iOS 16.4, *) {
			self.scrollBounceBehavior(.basedOnSize, axes: [.horizontal, .vertical])
		} else {
			self // not available yet
		}
	}
}

private let prettyDarkening: some ShapeStyle = Color.black.blendMode(.plusDarker)

struct Line: Shape {
	func path(in rect: CGRect) -> Path {
		.init {
			if rect.width < rect.height { // vertical
				$0.move(to: .init(x: rect.midX, y: rect.minY))
				$0.addLine(to: .init(x: rect.midX, y: rect.maxY))
			} else { // horizontal
				$0.move(to: .init(x: rect.minX, y: rect.midY))
				$0.addLine(to: .init(x: rect.maxX, y: rect.midY))
			}
		}
	}
}

#if DEBUG
@available(iOS 16.0, *)
struct RankRatingChart_Previews: PreviewProvider {
    static var previews: some View {
		List {
			Section {
				RankRatingChart(matches: PreviewData.matchList.matches)
			}
			.listRowInsets(.init())
			
			Section {
				RankRatingChart(
					matches: PreviewData.matchList.matches.map { $0 <- {
						$0.tierBeforeUpdate += 14
						$0.tierAfterUpdate += 14
					} },
					maxCount: 15
				)
			}
			.listRowInsets(.init())
		}
    }
}
#endif
