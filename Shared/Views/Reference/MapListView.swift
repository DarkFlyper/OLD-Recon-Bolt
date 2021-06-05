import SwiftUI

struct MapListView: View {
	@EnvironmentObject
	private var assetManager: AssetManager
	
	var body: some View {
		List {
			if let assets = assetManager.assets {
				let maps = assets.maps.values.sorted(on: \.displayName)
				ForEach(maps) { map in
					NavigationLink(destination: MapInfoView(map: map)) {
						MapCell(map: map)
					}
				}
			}
		}
		.navigationTitle("Maps")
	}
	
	struct MapCell: View {
		let map: MapInfo
		
		private let visualsHeight: CGFloat = 64
		
		var body: some View {
			HStack {
				mapIcon
				
				Text("\(map.displayName)")
					.fontWeight(.medium)
					.font(.title2)
				
				Spacer()
			}
			.padding(.vertical, 4)
		}
		
		private var mapIcon: some View {
			MapImage.splash(map.id)
				.scaledToFill()
				.frame(width: visualsHeight * 16/9, height: visualsHeight)
				.frame(minHeight: 0, alignment: .top) // text looks better on the top part
				.overlay(MapImage.Label(mapID: map.id))
				.mask(RoundedRectangle(cornerRadius: 4, style: .continuous))
		}
	}
}

#if DEBUG
struct MapListView_Previews: PreviewProvider {
	static var previews: some View {
		MapListView()
			.withToolbar()
			.inEachColorScheme()
			.environmentObject(AssetManager.forPreviews)
	}
}
#endif
