import SwiftUI
import ValorantAPI
import Collections
import Charts

@available(iOS 16.0, *)
struct RankRatingChart: View {
	var matches: [CompetitiveUpdate]
	
	@State var scaling: Double = 1.0
	@State var maxCount = 10
	
	@ScaledMetric(relativeTo: .caption2)
	private var verticalPadding = 11
	
	@CurrentGameConfig private var gameConfig
	
    var body: some View {
		let ranked = matches.lazy.filter(\.isRanked)
		let changes = ranked.prefix(maxCount).reversed() as Array
		let span = changes.lazy.map(\.eloAfterUpdate).minAndMax().map { $0.max - $0.min } ?? 0
		GeometryReader { geometry in
			ScrollView(.horizontal) {
				scrollableContent(changes: changes)
					.frame(width: max(12 * CGFloat(changes.count), geometry.size.width))
					.scaleEffect(x: -1, y: 1, anchor: .center) // unflip from below
			}
			.scaleEffect(x: -1, y: 1, anchor: .center) // flip to start at trailing edge
		}
		.frame(height: max(150, min(300, 1.5 * CGFloat(span))))
    }
	
	@ViewBuilder
	func scrollableContent(changes: [CompetitiveUpdate]) -> some View {
		if let seasons = $gameConfig.seasons {
			let hiddenCount = matches.count(where: \.isRanked) - changes.count
			chart(
				changes: changes, seasons: seasons,
				leadingPadding: hiddenCount > 0 ? 32 : 0 // space for "show more" button
			)
			.overlay(alignment: .leading) {
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
				}
			}
		} else {
			Text("Missing season data!")
				.foregroundStyle(.secondary)
				.frame(maxHeight: .infinity)
		}
	}
	
	func chart(changes: [CompetitiveUpdate], seasons: SeasonCollection.Accessor, leadingPadding: CGFloat) -> some View {
		Chart(changes.indexed(), id: \.index) { index, match in
			LineMark(
				x: .value("Match", index),
				y: .value("ELO", Double(match.eloAfterUpdate) * scaling),
				series: .value("Season", seasons.currentAct(at: match.startTime)?.nameWithEpisode ?? "")
			)
			.foregroundStyle(Color.white)
			.symbol(.circle)
		}
		.chartPlotStyle { $0.shadow(radius: 1, y: 1).compositingGroup().opacity(0.7).blendMode(.hardLight) }
		.chartXAxis(.hidden)
		.chartYAxis {
			AxisMarks(values: .stride(by: 100)) {
				AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
					.foregroundStyle(prettyDarkening.opacity(0.2))
			}
		}
		.chartYScale(domain: .automatic(includesZero: false), range: .plotDimension(padding: verticalPadding + 2.5))
		.chartXScale(range: .plotDimension(startPadding: 12 + leadingPadding, endPadding: 12))
		.chartBackground { chart in
			GeometryReader { geometry in
				ChartBackground(
					chart: chart,
					plotArea: geometry[chart.plotAreaFrame],
					matches: changes,
					seasons: seasons
				)
			}
		}
	}
	
	private struct ChartBackground: View {
		var tiers: [TierBackground] = []
		var seasonSpans: [(act: Act, area: CGRect)] = []
		
		init(chart: ChartProxy, plotArea: CGRect, matches: [CompetitiveUpdate], seasons: SeasonCollection.Accessor) {
			guard let (start, end) = matches.map(\.startTime).minAndMax() else { return }
			let collections = seasons.tierCollections(relevantTo: start...end)
			for (index, (act, tiers)) in collections.enumerated() {
				let startX = matches.firstIndex { act.timeSpan.contains($0.startTime) }
				guard let startX else { continue } // no match played in this act
				let endX = matches.suffix(from: startX).firstIndex { !act.timeSpan.contains($0.startTime) } ?? matches.endIndex
				let leading = index == 0 ? 0 : chart.position(forX: Double(startX) - 0.5)!
				let isLast = index == collections.count - 1
				let trailing = isLast ? plotArea.width : chart.position(forX: Double(endX) - 0.5)!
				let width = trailing - leading
				
				seasonSpans.append((act, CGRect(
					x: leading, y: plotArea.minY,
					width: width, height: plotArea.height
				)))
				
				let tiers = tiers.tiers.values.sorted(on: \.number)
				for (index, tier) in tiers.enumerated() {
					let bottom = chart.position(forY: tier.number * 100)!
					let nextBottom = tiers.elementIfValid(at: index + 1)
					let top = nextBottom.map { chart.position(forY: $0.number * 100)! } ?? min(0, bottom)
					guard (top..<bottom).overlaps(0..<plotArea.height) else { continue } // wouldn't be visible
					self.tiers.append(TierBackground(frame: CGRect(
						x: plotArea.minX + leading,
						y: plotArea.minY + top,
						width: width,
						height: bottom - top
					), tier: tier))
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
								.foregroundStyle(prettyDarkening.opacity(0.3))
							
							Color.clear // else nothing
						}
					}
					.offset(.init(span.area.origin))
			}
		}
		
		struct TierBackground: View {
			var frame: CGRect
			var tier: CompetitiveTier
			
			var body: some View {
				tier.backgroundColor
					.overlay {
						ViewThatFits {
							tier.icon?.view()
								.frame(width: 24)
								.padding(8)
								.shadow(color: .black.opacity(0.2), radius: 1, y: 1)
								.compositingGroup()
								.blendMode(.hardLight)
								.opacity(0.5)
							
							Color.clear // else nothing
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
struct RankedRatingChart_Previews: PreviewProvider {
    static var previews: some View {
		List {
			RankRatingChart(matches: PreviewData.matchList.matches)
				.listRowInsets(.init())
		}
    }
}
#endif
