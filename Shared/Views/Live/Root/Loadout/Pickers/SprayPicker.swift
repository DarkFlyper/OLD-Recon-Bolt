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
					spray.displayIcon.view()
						.frame(width: 48, height: 48)
					Text(spray.displayName)
					if spray.category == .contextual {
						Image(systemName: "exclamationmark.triangle")
							.foregroundStyle(.secondary)
					}
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

#if DEBUG
struct SprayPicker_Previews: PreviewProvider, PreviewProviderWithAssets {
	static func previews(assets: AssetCollection) -> some View {
		SprayPicker(
			selection: .constant(PreviewData.inventory.sprays.first!),
			inventory: PreviewData.inventory
		)
		.withToolbar()
	}
}
#endif
