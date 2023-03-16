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
				.foregroundColor(.valorantRed)
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
			// TODO: disclaimer about insufficient data
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
			.foregroundStyle(.secondary)
			
			distributionGrid(for: tally)
			/*
			EqualHStack(columnAlignment: .trailing, spacing: 8) {
				VStack {
					Text("\(tally.legshots) hits")
						.foregroundStyle(.secondary)
					percentageLabel(count: tally.legshots, total: tally.total)
				}
				
				VStack {
					Text("\(tally.bodyshots) hits")
						.foregroundStyle(.secondary)
					percentageLabel(count: tally.bodyshots, total: tally.total)
				}
				
				VStack {
					Text("\(tally.headshots) hits")
						.foregroundStyle(.secondary)
					percentageLabel(count: tally.headshots, total: tally.total)
				}
				
				Text("\(tally.total) total")
					.foregroundStyle(.secondary)
			}
			 */
		}
	}
	
	func percentageLabel(count: Int, total: Int) -> Text {
		Text(Double(count) / Double(total), format: .percent.precision(.fractionLength(1...1)))
	}
}

import CGeometry

@available(iOS 16.0, *)
struct EqualHStack: Layout {
	var columnAlignment: HorizontalAlignment = .center
	var spacing: CGFloat = 8
	
	var anchor: UnitPoint {
		switch columnAlignment {
		case .leading:
			return .leading
		case .center:
			return .center
		case .trailing:
			return .trailing
		default:
			return .center
		}
	}
	
	func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
		let subproposal = ProposedViewSize(
			width: proposal.width.map { $0 / .init(subviews.count) },
			height: proposal.height
		)
		let sizes = subviews.map { $0.sizeThatFits(subproposal) }
		return CGSize(
			width: proposal.width ?? (sizes.map(\.width).reduce(0, +) + spacing * .init(subviews.count - 1)),
			height: sizes.map(\.height).max() ?? 0
		)
	}
	
	func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
		let subwidth = (bounds.width - spacing * .init(subviews.count - 1)) / .init(subviews.count)
		let subproposal = ProposedViewSize(
			width: subwidth,
			height: proposal.height
		)
		let anchor = self.anchor
		let stride = subwidth + spacing
		for (i, view) in subviews.enumerated() {
			view.place(
				at: bounds.origin + CGVector(
					dx: subwidth * anchor.x + stride * .init(i),
					dy: bounds.height * anchor.y
				),
				anchor: anchor,
				proposal: subproposal
			)
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
