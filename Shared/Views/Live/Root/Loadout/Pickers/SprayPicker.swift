import SwiftUI
import ValorantAPI

struct SprayPicker: View {
	@Binding var selection: Spray.ID?
	var inventory: Inventory
	var isMidRound: Bool // some sprays cannot be equipped in the mid-round slot because they're too distracting
	
	var body: some View {
		AssetsUnwrappingView { assets in
			SearchableAssetPicker(
				allItems: assets.sprays,
				ownedItems: inventory.sprays
			) { spray in
				let isEnabled = !(isMidRound && spray.category == .contextual)
				SelectableRow(selection: $selection, item: spray.id) {
					spray.displayIcon.view()
						.frame(width: 48, height: 48)
					Text(spray.displayName)
				}
				.opacity(isEnabled ? 1 : 0.5)
				.saturation(isEnabled ? 1 : 0.5)
				.disabled(!isEnabled)
			} deselector: {
				SelectableRow(selection: $selection, item: nil) {
					Label("No Spray", systemImage: "xmark")
				}
			}
		}
		.navigationTitle("Choose Spray")
	}
}

extension SprayInfo: SearchableAsset {
	var searchableText: String { displayName }
}
