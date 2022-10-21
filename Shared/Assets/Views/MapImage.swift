import SwiftUI
import ValorantAPI

typealias MapImage = AssetImageView<_MapImageProvider>
struct _MapImageProvider: AssetImageProvider {
	static let assetPath = \AssetCollection.maps
}

extension MapImage {
	typealias Label = _MapImageLabel
	typealias LabelText = _MapImageLabelText
	
	static func splash(_ id: MapID) -> Self {
		Self(id: id, aspectRatio: 16/9, getImage: \.splash)
	}
	
	static func wideImage(_ id: MapID) -> Self {
		Self(id: id, aspectRatio: 4.56, shouldLoadImmediately: true, getImage: \.listViewIcon)
	}
	
	static func minimap(_ id: MapID) -> Self {
		Self(id: id, aspectRatio: 1, getImage: \.displayIcon)
	}
}

struct _MapImageLabel: View {
	let mapID: MapID
	
	var body: some View {
		MapImage.LabelText(mapID: mapID)
			.font(Font.callout.smallCaps().bold())
			.foregroundStyle(Material.regular)
			.shadow(radius: 1)
			.padding(.horizontal, 4) // visual alignment
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
			.colorScheme(.light)
	}
}

struct _MapImageLabelText: View {
	let mapID: MapID
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		Text(assets?.maps[mapID]?.displayName ?? "unknown")
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
