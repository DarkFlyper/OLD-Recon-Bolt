import SwiftUI
import ValorantAPI

struct MapInfoView: View {
	let map: MapInfo
	
	@Environment(\.verticalSizeClass) private var verticalSizeClass
	
	var body: some View {
		ScrollView {
			VStack(spacing: 16) {
				MapImage.splash(map.id).overlay(
					Text("\(map.id.rawValue)")
						.foregroundColor(.white)
						.shadow(radius: 8)
						.frame(maxHeight: .infinity, alignment: .bottom)
						.padding()
						.opacity(0.8)
				)
				.frame(maxHeight: verticalSizeClass == .compact ? 300 : nil)
				
				if map.displayIcon != nil {
					MagnifiableView {
						MapImage.displayIcon(map.id)
							.background(Material.ultraThin)
							.cornerRadius(16)
					}
					.zIndex(1)
					.frame(maxHeight: verticalSizeClass == .compact ? 300 : nil)
					.padding(.horizontal)
				} else {
					Text("No minimap available!")
						.foregroundColor(.secondary)
						.padding(.horizontal)
				}
			}
		}
		.clipped()
		.navigationTitle(map.displayName)
		.navigationBarTitleDisplayMode(.inline)
	}
}

#if DEBUG
struct MapInfoView_Previews: PreviewProvider {
	static var previews: some View {
		MapInfoView(
			map: AssetManager.forPreviews.assets!.maps[.breeze]!
		)
		.withToolbar()
		.inEachOrientation()
		.inEachColorScheme()
	}
}
#endif
