import SwiftUI
import ValorantAPI
import Collections
import Charts

@available(iOS 16.0, *)
struct RankedRatingChart: View {
	var matches: [CompetitiveUpdate]
	
    var body: some View {
		let changes = matches.filter(\.isRanked).prefix(30).reversed() as Array
		let span = changes.lazy.map(\.eloAfterUpdate).minAndMax().map { $0.max - $0.min } ?? 0
		AssetsUnwrappingView { assets in
			Chart(changes.indexed(), id: \.index) { index, match in
				LineMark(
					x: .value("Match", index),
					y: .value("ELO", match.eloAfterUpdate),
					series: .value("Season", assets.seasons.currentAct(at: match.startTime)?.nameWithEpisode ?? "")
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
			.chartYScale(domain: .automatic(includesZero: false))
			.chartXScale(range: .plotDimension(padding: 8))
			.chartBackground { chart in
				GeometryReader { geometry in
					ChartBackground(
						chart: chart,
						plotArea: geometry[chart.plotAreaFrame],
						matches: changes,
						assets: assets
					)
				}
			}
			.cornerRadius(4)
		}
		.frame(height: max(150, min(300, 100 * CGFloat(span / 100)))) // TODO: figure out if this makes sense despite changing the view height under the user's finger
		// TODO: maybe horizontal scrolling?
    }
	
	private struct ChartBackground: View {
		var tiers: [TierBackground] = []
		var seasonSpans: [(act: Act, area: CGRect)] = []
		
		init(chart: ChartProxy, plotArea: CGRect, matches: [CompetitiveUpdate], assets: AssetCollection) {
			guard let (start, end) = matches.map(\.startTime).minAndMax() else { return }
			let collections = assets.seasons.tierCollections(relevantTo: start...end)
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
								.blendMode(.luminosity)
								.opacity(0.5)
							
							Color.clear // else nothing
						}
					}
					.overlay(alignment: .leading) {
						VerticalLine()
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

struct VerticalLine: Shape {
	func path(in rect: CGRect) -> Path {
		.init {
			$0.move(to: .init(x: rect.midX, y: rect.minY))
			$0.addLine(to: .init(x: rect.midX, y: rect.maxY))
		}
	}
}

#if DEBUG
@available(iOS 16.0, *)
struct RankedRatingChart_Previews: PreviewProvider {
    static var previews: some View {
		List {
			RankedRatingChart(matches: PreviewData.matchList.matches)
				.padding(.vertical)
		}
    }
}
#endif
