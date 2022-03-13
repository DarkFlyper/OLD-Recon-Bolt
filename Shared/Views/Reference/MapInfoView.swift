import SwiftUI
import ValorantAPI
import CGeometry

struct MapInfoView: View {
	let map: MapInfo
	let magnificationScale = 3.0
	
	@State var isZoomedIn = false
	
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
					MagnifiableView(magnificationScale: magnificationScale) {
						MapImage.minimap(map.id)
							.overlay(calloutsOverlay())
							.compositingGroup()
							.background(Material.ultraThin)
							.cornerRadius(16)
					} onMagnifyToggle: { isZoomedIn = $0 }
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
	
	@ViewBuilder
	func calloutsOverlay() -> some View {
		GeometryReader { geometry in
			let callouts = map.callouts ?? []
			ForEach(callouts.indexed(), id: \.index) { _, callout in
				Text(callout.fullName)
					.font(isZoomedIn ? .callout : .system(size: 8))
					.padding(isZoomedIn ? 2 : 1)
					.background(.ultraThinMaterial)
					.scaleEffect(isZoomedIn ? 1 / magnificationScale : 1)
					.position(map.convert(callout.point) * geometry.size)
			}
		}
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
