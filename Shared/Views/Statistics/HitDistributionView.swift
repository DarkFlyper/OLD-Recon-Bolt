import SwiftUI
import ValorantAPI

@available(iOS 16.0, *)
struct HitDistributionView: View {
	typealias Tally = Statistics.HitDistribution.Tally
	
	var statistics: Statistics
	
	var distribution: Statistics.HitDistribution { statistics.hitDistribution }
	
	var body: some View {
		// TODO: breakdown by game as chart (stacked area)
		
		List {
			Section("Overall") {
				let overall = distribution.overall
				
				Grid(horizontalSpacing: 20, verticalSpacing: 4) {
					distributionRow("Head", count: overall.headshots, from: overall)
					distributionRow("Body", count: overall.bodyshots, from: overall)
					distributionRow("Legs", count: overall.legshots, from: overall)
					distributionRow("Total", count: overall.total, from: overall)
						.fontWeight(.semibold)
				}
			}
			
			byWeapon()
		}
		.navigationTitle("Hit Distribution")
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
		Section("Headshot Rate By Weapon") {
			Grid(horizontalSpacing: 20, verticalSpacing: 4) {
				ForEach(distribution.byWeapon.sorted(on: \.value.total).reversed(), id: \.key, content: weaponRow)
			}
		}
	}
	
	func weaponRow(for weapon: Weapon.ID?, tally: Tally) -> some View {
		GridRow {
			Stats.WeaponLabel(weapon: weapon)
				.gridColumnAlignment(.leading)
			
			Spacer()
			
			Text("\(tally.total) hits")
				.gridColumnAlignment(.trailing)
				.foregroundStyle(.secondary)
			
			Text(Double(tally.headshots) / Double(tally.total), format: .percent.precision(.fractionLength(1...1)))
				.gridColumnAlignment(.trailing)
		}
	}
}

#if DEBUG
@available(iOS 16.0, *)
struct HitDistributionView_Previews: PreviewProvider {
	static var previews: some View {
		HitDistributionView(statistics: PreviewData.statistics)
	}
}
#endif
