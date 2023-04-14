import SwiftUI

#if DEBUG
protocol PreviewProviderWithAssets: PreviewProvider {
	associatedtype PreviewsWithAssets: View
	
	@ViewBuilder
	static func previews(assets: AssetCollection) -> PreviewsWithAssets
}

extension PreviewProviderWithAssets {
	static var previews: some View {
		AssetProvider(content: previews)
	}
}

struct AssetProvider<Content: View>: View {
	@Environment(\.assets) private var assets
	@ViewBuilder var content: (AssetCollection) -> Content
	
	var body: some View {
		if let assets {
			content(assets)
		} else {
			Text(verbatim: "assets loading")
		}
	}
}
#endif
