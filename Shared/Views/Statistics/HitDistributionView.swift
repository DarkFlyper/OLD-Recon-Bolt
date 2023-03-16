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
				distributionGrid(for: distribution.overall)
			}
			
			byWeapon()
		}
		.navigationTitle("Hit Distribution")
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
			//.foregroundStyle(.secondary)
			.foregroundColor(.valorantRed)
			
			distributionGrid(for: tally)
		}
	}
	
	func percentageLabel(count: Int, total: Int) -> Text {
		Text(Double(count) / Double(total), format: .percent.precision(.fractionLength(1...1)))
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
