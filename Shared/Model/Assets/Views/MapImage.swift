import SwiftUI
import ValorantAPI

@dynamicMemberLookup
struct MapImage: View {
	@EnvironmentObject
	private var assetManager: AssetManager
	
	let mapID: MapID
	private let imageGetter: (MapInfo) -> AssetImage?
	
	static subscript(
		dynamicMember keyPath: KeyPath<MapInfo, AssetImage?>
	) -> (MapID) -> Self {
		{ Self(mapID: $0) { $0[keyPath: keyPath] } }
	}
	
	static subscript(
		dynamicMember keyPath: KeyPath<MapInfo, AssetImage>
	) -> (MapID) -> Self {
		{ Self(mapID: $0) { $0[keyPath: keyPath] } }
	}
	
	var body: some View {
		if let image = assetManager.assets?.maps[mapID].flatMap(imageGetter)?.imageIfLoaded {
			image
				.resizable()
				.scaledToFit()
		} else {
			Color.gray
		}
	}
	
	struct Label: View {
		let mapID: MapID
		
		var body: some View {
			Text(mapID.mapName ?? "unknown")
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
		let mapID = MapID(path: "/Game/Maps/Foxtrot/Foxtrot")
		Group {
			MapImage.splash(mapID)
				.overlay(MapImage.Label(mapID: mapID))
				.frame(height: 200)
		}
		.previewLayout(.sizeThatFits)
		.withPreviewAssets()
	}
}
#endif
