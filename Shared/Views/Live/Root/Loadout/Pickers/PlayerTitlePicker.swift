import SwiftUI
import ValorantAPI

struct PlayerTitlePicker: View {
	@Binding var selection: PlayerTitle.ID
	var inventory: Inventory
	
	var body: some View {
		SimpleSearchableAssetPicker(inventory: inventory) { (title: PlayerTitleInfo) in
			SelectableRow(selection: $selection, item: title.id) {
				title.textOrBlankDescription
			}
		}
		.navigationTitle("Choose Title")
	}
}

extension PlayerTitleInfo: SimpleSearchableAsset {
	static let assetPath = \AssetCollection.playerTitles
	static let inventoryPath = \Inventory.titles
	
	var searchableText: String { displayName }
}

extension PlayerTitleInfo {
	@ViewBuilder
	var textOrBlankDescription: some View {
		if let titleText = titleText {
			Text(titleText)
		} else {
			Text("No Title")
				.foregroundColor(.secondary)
		}
	}
}
