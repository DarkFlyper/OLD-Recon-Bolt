import SwiftUI
import ValorantAPI

typealias MapImage = _AssetImageView<_MapImageProvider>
struct _MapImageProvider: _AssetImageProvider {
	static let assetPath = \AssetCollection.maps
}

extension _AssetImageView where Provider == _MapImageProvider { // just using MapImage breaks the preview
	struct Label: View {
		let mapID: MapID
		
		var body: some View {
			LabelText(mapID: mapID)
				.font(Font.callout.smallCaps().bold())
				.foregroundStyle(Material.regular)
				.shadow(radius: 1)
				.padding(.horizontal, 4) // visual alignment
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
				.colorScheme(.light)
		}
	}
	
	struct LabelText: View {
		let mapID: MapID
		
		@Environment(\.assets) private var assets
		
		var body: some View {
			Text(assets?.maps[mapID]?.displayName ?? "unknown")
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
	}
}
#endif
