import SwiftUI

struct MapListView: View {
	@Environment(\.assets) private var assets
	
	var body: some View {
		List {
			if let assets {
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
		
		private let visualsHeight = 64.0
		
		var body: some View {
			HStack(spacing: 12) {
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
				.frame(height: visualsHeight)
				.fixedSize()
				.mask(RoundedRectangle(cornerRadius: 6, style: .continuous))
		}
	}
}

#if DEBUG
struct MapListView_Previews: PreviewProvider {
	static var previews: some View {
		MapListView()
			.withToolbar()
	}
}
#endif
