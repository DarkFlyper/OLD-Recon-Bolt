import SwiftUI
import Algorithms
import RegexBuilder

struct WeaponInfoView: View {
	let weapon: WeaponInfo
	
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	
	var body: some View {
		List {
			Section {
				weapon.displayIcon.view()
					.frame(maxHeight: 60)
					.frame(maxWidth: .infinity) // center
					.padding()
				
				if let data = weapon.shopData {
					LabeledRow(
						Text("Category", comment: "Weapon Reference"),
						value: Text(data.category)
					)
					
					LabeledRow(
						Text("Price", comment: "Weapon Reference"),
						value: Text("\(data.price) credits", comment: "Weapon Reference: price, always at least 150")
					)
				}
				
				NavigationLink {
					SkinsList(weapon: weapon)
				} label: {
					HStack {
						Text("Skins", comment: "Weapon Reference: button")
						Spacer()
						Text(weapon.skins.count - 2 /* standard, random */, format: .number)
							.foregroundStyle(.secondary)
					}
				}
				.font(.body.weight(.medium))
			}
			
			if let stats = weapon.stats {
				Section {
					statsRows(for: stats)
				} header: {
					Text("Weapon Statistics", comment: "Weapon Reference: section")
				}
				.headerProminence(.increased)
			}
		}
		.background(Color.groupedBackground)
		.navigationTitle(weapon.displayName)
	}
	
	@ViewBuilder
	func statsRows(for stats: WeaponStats) -> some View {
		LabeledRow(
			Text("Fire Rate", comment: "Weapon Reference: stats"),
			value: Text("\(stats.fireRate, format: .number) bullets/sec", comment: "Weapon Reference: stats")
		)
		LabeledRow(
			Text("Magazine Size", comment: "Weapon Reference: stats"),
			value: Text("\(stats.magazineSize) bullets", comment: "Weapon Reference: stats") // TODO: stringsdict
		)
		
		damageRangesGrid(for: stats.damageRanges)
		
		LabeledRow(
			Text("Equip Time", comment: "Weapon Reference: stats"),
			seconds: stats.equipTime
		)
		LabeledRow(
			Text("Reload Time", comment: "Weapon Reference: stats"),
			seconds: stats.reloadTime
		)
		LabeledRow(
			Text("Run Speed", comment: "Weapon Reference: stats"),
			value: Text(stats.runSpeedMultiplier, format: .percent)
		)
		if stats.shotgunPelletCount > 1 {
			LabeledRow(
				Text("Shotgun Pellets", comment: "Weapon Reference: stats"),
				value: Text("\(stats.shotgunPelletCount) pellets", comment: "Weapon Reference: stats") // TODO: stringsdict
			)
		}
		LabeledRow(
			Text("First Bullet Spread", comment: "Weapon Reference: stats"),
			value: Text("\(stats.firstBulletAccuracy, format: .number)°", comment: "Weapon Reference: stats")
		)
	}
	
	@ViewBuilder
	func damageRangesGrid(for ranges: [WeaponStats.DamageRange]) -> some View {
		if #available(iOS 16.0, *), horizontalSizeClass == .regular {
			Grid(alignment: .trailing, horizontalSpacing: 20, verticalSpacing: 4) {
				GridRow {
					Text("Range", comment: "Weapon Reference: stats")
					Text("Head", comment: "Weapon Reference: stats")
					Text("Body", comment: "Weapon Reference: stats")
					Text("Legs", comment: "Weapon Reference: stats")
				}
				.gridCellAnchor(.center)
				.fontWeight(.semibold)
				
				Divider()
					.gridCellUnsizedAxes(.horizontal)
				
				ForEach(ranges, id: \.start) { range in
					GridRow {
						Text("\(range.start) – \(range.end)m", comment: "Weapon Reference: stats: damage range")
							.fontWeight(.medium)
						Text(range.damageToHead, format: .number.precision(.fractionLength(2)))
						Text(range.damageToBody, format: .number.precision(.fractionLength(2)))
						Text(range.damageToLegs, format: .number.precision(.fractionLength(2)))
					}
					.monospacedDigit()
				}
			}
			.padding()
			.background(Color.tertiaryGroupedBackground)
			.cornerRadius(8)
			.frame(maxWidth: .infinity)
			.aligningListRowSeparator()
		} else {
			ForEach(ranges, id: \.start) { range in
				HStack {
					VStack(alignment: .leading) {
						Text("Damage", comment: "Weapon Reference: stats")
						Text("\(range.start) – \(range.end)m", comment: "Weapon Reference: stats: damage range")
					}
					.foregroundStyle(.secondary)
					
					Spacer()
					
					VStack(alignment: .trailing) {
						HStack {
							Text("Head", comment: "Weapon Reference: stats").foregroundStyle(.secondary)
							Text(range.damageToHead, format: .number.precision(.fractionLength(2)))
						}
						HStack {
							Text("Body", comment: "Weapon Reference: stats").foregroundStyle(.secondary)
							Text(range.damageToBody, format: .number.precision(.fractionLength(2)))
						}
						HStack {
							Text("Legs", comment: "Weapon Reference: stats").foregroundStyle(.secondary)
							Text(range.damageToLegs, format: .number.precision(.fractionLength(2)))
						}
					}
					.monospacedDigit()
				}
			}
		}
	}
}

private struct SkinsList: View {
	private static let specialThemes: Set<WeaponSkin.Theme.ID> = [.standard, .random]
	
	var weapon: WeaponInfo
	@State var search = ""
	
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	
	var body: some View {
		let skins = weapon.skins
			.filter { !Self.specialThemes.contains($0.themeID) }
			.filter { searchAccepts(skin: $0.displayName) }
			.sorted(on: \.displayName)
		
		List(skins) { skin in
			NavigationLink {
				SkinDetailsView(skin: skin)
			} label: {
				let icon = (skin.chromas.first?.fullRender).view()
				if horizontalSizeClass == .regular { // wide
					HStack {
						Text(skin.displayName)
						Spacer()
						icon.frame(height: 60)
							.fixedSize()
					}
				} else {
					VStack {
						icon.frame(maxHeight: 60)
						Text(skin.displayName)
							.frame(maxWidth: .infinity, alignment: .leading)
					}
					.padding(.vertical)
					.aligningListRowSeparator()
				}
			}
			.font(.title3.weight(.medium))
		}
		.navigationTitle(Text("Skins", comment: "Weapon Reference: skins list title"))
		.searchable(text: $search)
	}
	
	func searchAccepts(skin: String) -> Bool {
		if #available(iOS 16.1, *) { // due to a bug from apple, this crashes in 16.0
			return skin.firstMatch(of: Regex {
				Anchor.wordBoundary
				search
			}.ignoresCase()) != nil
		} else {
			return skin.lowercased().starts(with: search.lowercased()) // basic fallback
		}
	}
}

private extension LabeledRow {
	init(_ label: Text, seconds: TimeInterval) {
		self.init(label, value: Text(
			"\(seconds, format: .number.precision(.fractionLength(2)))s",
			comment: "Weapon Reference: time in seconds (with decimal digits)"
		))
	}
}

extension TimeInterval {
	struct TimeIntervalFormatStyle: FormatStyle {
		let style: Date.ComponentsFormatStyle.Style
		let fields: Set<Date.ComponentsFormatStyle.Field>?
		
		func format(_ value: TimeInterval) -> String {
			let start = Date(timeIntervalSinceReferenceDate: 0)
			let end = Date(timeIntervalSinceReferenceDate: value)
			return (start..<end).formatted(.components(style: style, fields: fields))
		}
	}
}

extension FormatStyle where Self == TimeInterval.TimeIntervalFormatStyle {
	static func timeInterval(
		style: Date.ComponentsFormatStyle.Style,
		fields: Set<Date.ComponentsFormatStyle.Field>? = nil
	) -> Self {
		.init(style: style, fields: fields)
	}
}

#if DEBUG
struct WeaponInfoView_Previews: PreviewProvider, PreviewProviderWithAssets {
	static func previews(assets: AssetCollection) -> some View {
		WeaponInfoView(weapon: assets.weapons[.bucky]!)
			.withToolbar()
		
		NavigationLink("Example" as String, isActive: .constant(true)) {
			WeaponInfoView(weapon: assets.weapons[.phantom]!)
		}
		.withToolbar()
	}
}
#endif
