import SwiftUI
import ValorantAPI

struct PlayerCardPicker: View {
	@Binding var selection: PlayerCard.ID
	var inventory: Inventory
	
	var body: some View {
		SimpleSearchableAssetPicker(inventory: inventory) { (card: PlayerCardInfo) in
			SelectableRow(selection: $selection, item: card.id) {
				card.smallArt.view()
					.frame(width: 48, height: 48)
				Text(card.displayName)
					.foregroundColor(.primary)
			}
		}
		.navigationTitle("Choose Card")
	}
}

extension PlayerCardInfo: SimpleSearchableAsset {
	static let assetPath = \AssetCollection.playerCards
	static let inventoryPath = \Inventory.cards
	
	var searchableText: String { displayName }
}
