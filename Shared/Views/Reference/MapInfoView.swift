import SwiftUI
import ValorantAPI

struct MapInfoView: View {
	let map: MapInfo
	
	var body: some View {
		ScrollView {
			VStack {
				MapImage.splash(map.id).overlay(
					Text("\(map.id.path)")
						.foregroundColor(.white)
						.shadow(radius: 8)
						.frame(maxHeight: .infinity, alignment: .bottom)
						.padding()
						.opacity(0.8)
				)
				
				if map.displayIcon != nil {
					MapImage.displayIcon(map.id)
				} else {
					Text("No minimap available!")
				}
			}
		}
		.navigationTitle(map.displayName)
	}
}

#if DEBUG
struct MapInfoView_Previews: PreviewProvider {
	static var previews: some View {
		MapInfoView(
			map: AssetManager.forPreviews.assets!
				.maps[MapID(path: "/Game/Maps/Triad/Triad")]!
		)
		.withToolbar()
		.inEachColorScheme()
		.environmentObject(AssetManager.forPreviews)
	}
}
#endif
