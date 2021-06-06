import SwiftUI
import ValorantAPI

struct MapInfoView: View {
	let map: MapInfo
	
	@State private var isShowingFullscreenMap = false
	
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
						.onTapGesture { isShowingFullscreenMap = true }
						.fullScreenCover(isPresented: $isShowingFullscreenMap) {
							Lightbox { MapImage.displayIcon(map.id) }
						}
				} else {
					Text("No minimap available!")
				}
			}
		}
		.navigationTitle(map.displayName)
		.navigationBarTitleDisplayMode(.inline)
	}
}

#if DEBUG
struct MapInfoView_Previews: PreviewProvider {
	static var previews: some View {
		Lightbox {
			MapImage.displayIcon(MapID(path: "/Game/Maps/Foxtrot/Foxtrot"))
		}
		.environmentObject(AssetManager.forPreviews)
		
		MapInfoView(
			map: AssetManager.forPreviews.assets!
				.maps[MapID(path: "/Game/Maps/Foxtrot/Foxtrot")]!
		)
		.withToolbar()
		.inEachColorScheme()
		.environmentObject(AssetManager.forPreviews)
	}
}
#endif
