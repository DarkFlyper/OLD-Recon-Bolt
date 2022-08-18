import SwiftUI
import ValorantAPI

struct WeaponLoadoutView: View {
	@Binding var loadout: UpdatableLoadout
	var inventory: Inventory
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		List {
			ForEach(Weapon.ID.orderInCollection, id: \.self) { gunID in
				let gun = $loadout[dynamicMember: \.guns[gunID]!]
				Section {
					GunCell(gun: gun, loadout: $loadout, inventory: inventory)
				} header: {
					Text(assets?.weapons[gun.wrappedValue.id]?.displayName ?? "")
				}
			}
		}
		.navigationTitle("Weapons")
	}
	
	struct GunCell: View {
		@Binding var gun: Loadout.Gun
		@Binding var loadout: UpdatableLoadout
		var inventory: Inventory
		
		@Environment(\.assets) private var assets
		
		var body: some View {
			if let resolved = assets?.resolveSkin(gun.skin.level) {
				NavigationLink {
					GunCustomizer(gun: $gun, loadout: $loadout, resolved: resolved, inventory: inventory)
				} label: {
					let chroma = resolved.chroma(gun.skin.chroma)
					HStack {
						if let buddy = gun.buddy {
							(assets?.buddies[buddy.buddy]?.displayIcon)
								.view()
								.frame(width: 60)
						}
						let icon = chroma?.fullRender ?? chroma?.displayIcon ?? resolved.displayIcon
						icon.view()
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
			loadout: .constant(.init(PreviewData.loadout)),
			inventory: PreviewData.inventory
		)
		.withToolbar()
    }
}
#endif
