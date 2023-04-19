import SwiftUI
import ValorantAPI
import Charts
import Collections
import HandyOperators

private typealias Tally = Statistics.WinRate.Tally

@available(iOS 16.0, *)
struct HitDistributionView: View {
	typealias Tally = Statistics.HitDistribution.Tally
	
	var statistics: Statistics
	
	@State var smoothing = 0.0
	
	var distribution: Statistics.HitDistribution {
		statistics.hitDistribution
	}
	
	var body: some View {
		Group {
			if distribution.byMatch.isEmpty {
				GroupBox {
					VStack(spacing: 8) {
						Text("Not enough data!", comment: "Hit Distribution Stats: error")
							.font(.title2.bold())
						Text("Select more matches to see data on hit distribution. Deathmatch, Escalation, and other modes don't provide the necessary information.", comment: "Hit Distribution Stats: error")
					}
				}
				.frame(maxWidth: .infinity)
				.foregroundStyle(.secondary)
			} else {
				List {
					contents()
				}
			}
		}
		.navigationTitle(Text("Hit Distribution", comment: "Hit Distribution Stats: title"))
	}
	
	@ViewBuilder
	func contents() -> some View {
		Section {
			chartOverTime()
		} header: {
			Text("Distribution Over Time", comment: "Hit Distribution Stats: section")
		} footer: {
			let count = distribution.byMatch.count
			Text("Data from \(count) game(s) (\(statistics.matches.count - count) skipped lacking data)", comment: "Hit Distribution Stats")
				.font(.footnote)
		}
		
		Section {
			distributionGrid(for: distribution.overall)
		} header: {
			Text("Overall", comment: "Hit Distribution Stats: section")
		}
		
		byWeapon()
	}
	
	@ViewBuilder
	func chartOverTime() -> some View {
		ChartOverTime(
			distribution: distribution,
			smoothingWindowSize: Int(ceil(pow(smoothingLogBase, smoothing)))
		)
		.padding(.vertical)
		.aligningListRowSeparator()
		
		HStack {
			Text("Smoothing", comment: "Hit Distribution Stats: smoothing slider")
			
			Slider(
				value: $smoothing,
				in: 0...max(1, log(CGFloat(distribution.byMatch.count - 1)) / log(smoothingLogBase)),
				step: 1
			)
		}
	}
	
	func distributionGrid(for tally: Tally) -> some View {
		Grid(horizontalSpacing: 20, verticalSpacing: 4) {
			distributionRow(Text("Head", comment: "Hit Distribution Stats: region"), count: tally.headshots, from: tally)
			distributionRow(Text("Body", comment: "Hit Distribution Stats: region"), count: tally.bodyshots, from: tally)
			distributionRow(Text("Legs", comment: "Hit Distribution Stats: region"), count: tally.legshots, from: tally)
			distributionRow(Text("Total", comment: "Hit Distribution Stats: region"), count: tally.total, from: tally)
				.fontWeight(.semibold)
				.foregroundStyle(.secondary)
		}
	}
	
	func distributionRow(_ name: Text, count: Int, from tally: Tally) -> some View {
		GridRow {
			name
				.gridColumnAlignment(.leading)
			
			Spacer()
			
			Text("\(count) hits", comment: "Hit Distribution Stats: hit count")
				.gridColumnAlignment(.trailing)
				.foregroundStyle(.secondary)
			
			Text(Double(count) / Double(tally.total), format: .precisePercent)
				.gridColumnAlignment(.trailing)
		}
		.monospacedDigit()
	}
	
	func byWeapon() -> some View {
		Section {
			ForEach(distribution.byWeapon.sorted(on: \.value.total).reversed(), id: \.key, content: weaponRow)
		} header: {
			Text("By Weapon", comment: "Hit Distribution Stats: section")
		} footer: {
			Text("Unfortunately, Valorant doesn't store information about which weapon was used for each hit. All we get is the weapon you started the round with and what weapon you used for each kill. Recon Bolt guesses the weapon involved in each damage based on this information, but it cannot be perfect (and neither can any other tracker).", comment: "Hit Distribution Stats: footnote")
				.frame(maxWidth: .infinity, alignment: .leading)
		}
	}
	
	@ScaledMetric(relativeTo: .headline) private var weaponIconHeight = 32
	@ScaledMetric private var numberWidth = 64
	
	func weaponRow(for weapon: Weapon.ID, tally: Tally) -> some View {
		VStack {
			HStack {
				Stats.WeaponLabel(weapon: weapon)
					.font(.title3.weight(.bold))
				
				Spacer()
				
				WeaponImage.killStreamIcon(weapon)
					.frame(maxHeight: weaponIconHeight)
			}
			.foregroundColor(.valorantRed)
			
			distributionGrid(for: tally)
		}
	}
	
	struct ChartOverTime: View {
		var distribution: Statistics.HitDistribution
		var smoothingWindowSize: Int
		
		var body: some View {
			let average = Double(distribution.overall.headshots) / Double(distribution.overall.total)
			let percentage = average.formatted(.precisePercent)
			
			let smoothed = distribution.byMatch
				.reversed()
				.windows(ofCount: smoothingWindowSize)
				.enumerated()
				.map { index, window in
					window.reduce(into: FractionalTally()) { $0 += $1.tally }
				}
			<- {
				if $0.count == 1 {
					$0.append(contentsOf: $0)
				}
			}
			
			Chart {
				ForEach(smoothed.indices, id: \.self) { index in
					ForEach(smoothed[index].data(), id: \.key) { key, hits in
						AreaMark(x: .value("Match", index), y: .value("Hits", hits), stacking: .normalized)
							.foregroundStyle(by: .value("Part", key))
					}
				}
				
				RuleMark(y: .value("Hits", 100 * (1 - average)))
					.lineStyle(.init(lineWidth: 1, dash: [4, 2]))
					.annotation(position: .bottom) {
						Text("Average: \(percentage)", comment: "Hit Distribution Stats: average HS%")
							.font(.caption)
							.foregroundStyle(.negative)
					}
					.foregroundStyle(.negative)
			}
			.chartPlotStyle {
				$0.cornerRadius(6)
			}
			.chartXAxis(.hidden)
			.chartYAxis(.hidden)
			.chartForegroundStyleScale([
				HitRegionKey.legs: Color.valorantRed,
				HitRegionKey.body: Color.valorantBlue,
				HitRegionKey.head: Color.valorantSelf,
			])
			.compositingGroup()
		}
	}
}

@available(iOS 16.0, *)
extension HitDistributionView {
	init(statistics: Statistics) {
		let smoothingWindowSize = max(1, statistics.hitDistribution.byMatch.count / 5)
		self.init(
			statistics: statistics,
			smoothing: floor(log(CGFloat(smoothingWindowSize)) / log(smoothingLogBase))
		)
	}
	
	static func overview(statistics: Statistics) -> ChartOverTime? {
		.init(
			distribution: statistics.hitDistribution,
			smoothingWindowSize: max(1, statistics.hitDistribution.byMatch.count / 5)
		)
	}
}

private let smoothingLogBase = 1.5

private struct FractionalTally {
	var headshots: Double = 0.0
	var bodyshots: Double = 0.0
	var legshots: Double = 0.0
	
	static func += (lhs: inout Self, rhs: Self) {
		lhs.headshots += rhs.headshots
		lhs.bodyshots += rhs.bodyshots
		lhs.legshots += rhs.legshots
	}
	
	static func += (lhs: inout Self, rhs: Statistics.HitDistribution.Tally) {
		lhs += rhs.normalized()
	}
	
	@available(iOS 16.0, *)
	func data() -> [(key: HitRegionKey, hits: Double)] {
		[ // order matters
			(.legs, legshots),
			(.body, bodyshots),
			(.head, headshots),
		]
	}
}

@available(iOS 16.0, *)
private enum HitRegionKey: Plottable {
	case legs, body, head
	
	init?(primitivePlottable: String) {
		fatalError()
	}
	
	var primitivePlottable: String {
		switch self {
		case .legs:
			return String(localized: "Legs")
		case .body:
			return String(localized: "Body")
		case .head:
			return String(localized: "Head")
		}
	}
}
private extension Statistics.HitDistribution.Tally {
	func normalized() -> FractionalTally {
		.init(
			headshots: Double(headshots) / .init(total),
			bodyshots: Double(bodyshots) / .init(total),
			legshots: Double(legshots) / .init(total)
		)
	}
}

@available(iOS 16.0, *)
extension Match.ID: Plottable {
	public var primitivePlottable: String {
		description
	}
	
	public init?(primitivePlottable: String) {
		self.init(primitivePlottable)
	}
}

#if DEBUG
@available(iOS 16.0, *)
struct HitDistributionView_Previews: PreviewProvider {
	static var previews: some View {
		HitDistributionView(statistics: PreviewData.statistics)
			.withToolbar()
		
		HitDistributionView(statistics: .init(userID: PreviewData.userID, matches: [PreviewData.singleMatch]))
			.withToolbar()
	}
}
#endif
