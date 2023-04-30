import SwiftUI

struct WeaponListView: View {
	@Environment(\.assets) private var assets
	@ScaledMetric(relativeTo: .title2) private var weaponIconHeight = 36
	
	var body: some View {
		List {
			if let assets {
				let weapons = assets.weapons.values.sorted(on: \.displayName)
				ForEach(weapons) { weapon in
					NavigationLink(destination: WeaponInfoView(weapon: weapon)) {
						row(for: weapon)
					}
				}
			}
		}
		.navigationTitle("Weapons")
	}
	
	func row(for weapon: WeaponInfo) -> some View {
		HStack(spacing: 12) {
			Text("\(weapon.displayName)")
				.fontWeight(.medium)
				.font(.title2)
			
			Spacer()
			
			WeaponImage.killStreamIcon(weapon.id)
				.frame(maxHeight: weaponIconHeight)
				.foregroundColor(.valorantRed)
		}
		.padding(.vertical, 4)
	}
}

#if DEBUG
struct WeaponListView_Previews: PreviewProvider {
	static var previews: some View {
		WeaponListView()
			.withToolbar()
	}
}
#endif
