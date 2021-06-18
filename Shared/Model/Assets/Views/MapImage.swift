import SwiftUI
import ValorantAPI

typealias MapImage = _AssetImageView<_MapImageProvider>
struct _MapImageProvider: _AssetImageProvider {
	static let assetPath = \AssetCollection.maps
}

extension MapImage {
	struct Label: View {
		@EnvironmentObject
		private var assetManager: AssetManager
		
		let mapID: MapID
		
		var body: some View {
			Text(assetManager.assets?.maps[mapID]?.displayName ?? "unknown")
				.font(Font.callout.smallCaps())
				.bold()
				.foregroundStyle(Material.regular)
				.shadow(radius: 1)
				.padding(.leading, 4) // visual alignment
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
				.colorScheme(.light)
		}
	}
}

#if DEBUG
struct MapImage_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			MapImage.splash(.breeze)
				.overlay(MapImage.Label(mapID: .breeze))
				.frame(height: 200)
		}
		.previewLayout(.sizeThatFits)
		.withPreviewAssets()
	}
}
#endif
