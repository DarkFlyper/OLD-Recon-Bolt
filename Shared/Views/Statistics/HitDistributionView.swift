import SwiftUI
import ValorantAPI
import Charts
import Collections

private typealias Tally = Statistics.WinRate.Tally

@available(iOS 16.0, *)
struct HitDistributionView: View {
	typealias Tally = Statistics.HitDistribution.Tally
	
	var statistics: Statistics
	
	@State var smoothing = 0.0
	private let smoothingLogBase = 1.5
	
	var distribution: Statistics.HitDistribution {
		statistics.hitDistribution
	}
	
	var body: some View {
		Group {
			if distribution.byMatch.isEmpty {
				GroupBox {
					VStack(spacing: 8) {
						Text("Not enough data!")
							.font(.title2.bold())
						Text("Select more matches to see data on hit distribution. Deathmatch, Escalation, and other modes don't provide the necessary information.")
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
		.navigationTitle("Hit Distribution")
	}
	
	@ViewBuilder
	func contents() -> some View {
		Section {
			chartOverTime()
		} header: {
			Text("Distribution Over Time")
		} footer: {
			let count = distribution.byMatch.count
			Text("Data from \(count) games (\(statistics.matches.count - count) skipped lacking data)")
				.font(.footnote)
		}
		
		Section("Overall") {
			distributionGrid(for: distribution.overall)
		}
		
		byWeapon()
	}
	
	@ViewBuilder
	func chartOverTime() -> some View {
		let average = Double(distribution.overall.headshots) / Double(distribution.overall.total)
		let percentage = percentageLabel(
			count: distribution.overall.headshots,
			total: distribution.overall.total
		)
		
		let windowSize = Int(ceil(pow(smoothingLogBase, smoothing)))
		let smoothed = distribution.byMatch
			.reversed()
			.windows(ofCount: windowSize)
			.enumerated()
			.map { index, window in
				window.reduce(into: FractionalTally()) { $0 += $1.tally }
			}
		
		Chart {
			ForEach(smoothed.indices, id: \.self) { index in
				ForEach(smoothed[index].data(), id: \.name) { name, hits in
					AreaMark(x: .value("Match", index), y: .value("Hits", hits), stacking: .normalized)
						.foregroundStyle(by: .value("Part", name))
				}
			}
			
			RuleMark(y: .value("Hits", 100 * (1 - average)))
				.lineStyle(.init(lineWidth: 1, dash: [4, 2]))
				.annotation(position: .bottom) {
					Text("Average: \(percentage)")
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
			"Legs": Color.valorantSelf,
			"Body": Color.valorantBlue,
			"Head": Color.valorantRed,
		])
		.compositingGroup()
		.padding(.vertical)
		.aligningListRowSeparator()
		
		HStack {
			Text("Smoothing")
			
			Slider(
				value: $smoothing,
				in: 0...max(1, log(CGFloat(distribution.byMatch.count - 1)) / log(smoothingLogBase)),
				step: 1
			)
		}
	}
	
	func distributionGrid(for tally: Tally) -> some View {
		Grid(horizontalSpacing: 20, verticalSpacing: 4) {
			distributionRow("Head", count: tally.headshots, from: tally)
			distributionRow("Body", count: tally.bodyshots, from: tally)
			distributionRow("Legs", count: tally.legshots, from: tally)
			distributionRow("Total", count: tally.total, from: tally)
				.fontWeight(.semibold)
				.foregroundStyle(.secondary)
		}
	}
	
	func distributionRow(_ name: LocalizedStringKey, count: Int, from tally: Tally) -> some View {
		GridRow {
			Text(name)
				.gridColumnAlignment(.leading)
			
			Spacer()
			
			Text("\(count) hits")
				.gridColumnAlignment(.trailing)
				.foregroundStyle(.secondary)
			
			Text(Double(count) / Double(tally.total), format: .percent.precision(.fractionLength(1...1)))
				.gridColumnAlignment(.trailing)
		}
		.monospacedDigit()
	}
	
	func byWeapon() -> some View {
		Section {
			ForEach(distribution.byWeapon.sorted(on: \.value.total).reversed(), id: \.key, content: weaponRow)
		} header: {
			Text("By Weapon")
		} footer: {
			Text("Unfortunately, Valorant doesn't store information about which weapon was used for each hit. All we get is the weapon you started the round with and what weapon you used for each kill. Recon Bolt guesses the weapon involved in each damage based on this information, but it cannot be perfect (and neither can any other tracker).")
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
	
	func percentageLabel(count: Int, total: Int) -> String {
		(Double(count) / Double(total)).formatted(.percent.precision(.fractionLength(1...1)))
	}
}

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
	
	// TODO: use
	func data() -> [(name: String, hits: Double)] {
		[
			("Head", headshots),
			("Body", bodyshots),
			("Legs", legshots),
		]
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
	}
}
#endif
