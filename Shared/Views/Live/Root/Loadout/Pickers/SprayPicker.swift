import SwiftUI
import ValorantAPI

struct SprayPicker: View {
	@Binding var selection: Spray.ID?
	var inventory: Inventory
	
	var body: some View {
		AssetsUnwrappingView { assets in
			SearchableAssetPicker(
				allItems: assets.sprays,
				ownedItems: inventory.sprays
			) { spray in
				SelectableRow(selection: $selection, item: spray.id) {
					spray.bestIcon.view()
						.frame(width: 48, height: 48)
					Text(spray.displayName)
				}
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
