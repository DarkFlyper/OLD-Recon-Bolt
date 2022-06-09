import SwiftUI
import ValorantAPI

struct WeaponLoadoutView: View {
	static let weaponOrder: [Weapon.ID: Int] = .init(
		uniqueKeysWithValues: Weapon.ID.orderInCollection
			.enumerated()
			.lazy
			.map { ($1, $0) }
	)
	
	@Binding var loadout: Loadout
	var inventory: Inventory
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		List {
			let sorted = loadout.guns.sorted(on: { Self.weaponOrder[$0.id] ?? 100 })
			ForEach(sorted, id: \.id) { gun in
				let index = loadout.guns.firstIndex { $0.id == gun.id }!
				let gun = $loadout.guns[index]
				Section {
					GunCell(gun: gun, inventory: inventory)
				} header: {
					Text(assets?.weapons[gun.wrappedValue.id]?.displayName ?? "")
				}
			}
		}
		.navigationTitle("Weapons")
	}
	
	struct GunCell: View {
		@Binding var gun: Loadout.Gun
		var inventory: Inventory
		
		@Environment(\.assets) private var assets
		
		var body: some View {
			if let resolved = assets?.resolveSkin(gun.skin.level) {
				NavigationLink {
					GunCustomizer(gun: $gun, resolved: resolved, inventory: inventory)
				} label: {
					let chroma = resolved.chroma(gun.skin.chroma)
					HStack {
						if let buddy = gun.buddy {
							(assets?.buddies[buddy.buddy]?.displayIcon)
								.asyncImageOrPlaceholder()
								.frame(width: 60)
						}
						let icon = chroma?.displayIcon ?? chroma?.fullRender ?? resolved.displayIcon
						icon.asyncImageOrPlaceholder()
							.frame(maxWidth: .infinity)
					}
					.frame(height: 80)
					.padding(.vertical, 8)
				}
			}
		}
	}
}

#if DEBUG
struct WeaponLoadoutView_Previews: PreviewProvider {
	static var previews: some View {
		WeaponLoadoutView(
			loadout: .constant(PreviewData.loadout),
			inventory: PreviewData.inventory
		)
		.withToolbar()
    }
}
#endif
