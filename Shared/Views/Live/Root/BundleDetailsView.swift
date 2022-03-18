import SwiftUI
import ValorantAPI

struct BundleDetailsView: View {
	var bundle: StoreBundle
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		if let info = assets?.bundles[bundle.assetID] {
			ScrollView {
				info.displayIcon.asyncImage()
			}
			.background(Color.groupedBackground)
			.navigationTitle(info.displayName)
		} else {
			VStack(spacing: 8) {
				Text("Unknown bundle!")
				Text("Are your assets outdated?")
			}
			.foregroundColor(.secondary)
			.padding()
		}
	}
}

#if DEBUG
struct BundleDetailsView_Previews: PreviewProvider {
	static var previews: some View {
		BundleDetailsView(bundle: PreviewData.storefront.featuredBundle.bundles.first!)
			.withToolbar()
	}
}
#endif
