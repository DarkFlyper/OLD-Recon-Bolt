import SwiftUI
import ValorantAPI

struct SprayPicker: View {
	@Binding var selection: Spray.ID?
	var inventory: Inventory
	
	var body: some View {
		SimpleSearchableAssetPicker(inventory: inventory) { (spray: SprayInfo) in
			SelectableRow(selection: $selection, item: spray.id) {
				spray.bestIcon.view()
					.frame(width: 48, height: 48)
				Text(spray.displayName)
			}
		}
		.navigationTitle("Choose Spray")
	}
}

extension SprayInfo: SimpleSearchableAsset {
	static let assetPath = \AssetCollection.sprays
	static let inventoryPath = \Inventory.sprays
	
	var searchableText: String { displayName }
}
