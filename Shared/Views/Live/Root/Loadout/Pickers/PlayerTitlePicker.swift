import SwiftUI
import ValorantAPI

struct PlayerTitlePicker: View {
	@Binding var selection: PlayerTitle.ID
	var inventory: Inventory
	
	var body: some View {
		SimpleSearchableAssetPicker(inventory: inventory) { (title: PlayerTitleInfo) in
			SelectableRow(selection: $selection, item: title.id) {
				PlayerTitleLabel(titleID: title.id)
			}
		}
		.navigationTitle("Choose Title")
	}
}

extension PlayerTitleInfo: SimpleSearchableAsset {
	static let assetPath = \AssetCollection.playerTitles
	static let inventoryPath = \Inventory.titles
	
	var searchableText: String { displayName ?? "" }
	static var defaultItems: [ID] { [.noTitle] }
}

struct PlayerTitleLabel: View {
	var titleID: PlayerTitle.ID
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		let blank = Text("No Title")
			.foregroundStyle(.secondary)
		
		if let title = assets?.playerTitles[titleID] {
			if let text = title.titleText {
				Text(text)
			} else {
				blank
			}
		} else if titleID.isPseudoNull {
			blank
		} else {
			Text("Unknown Title", comment: "placeholder")
				.foregroundStyle(.secondary)
		}
	}
}
