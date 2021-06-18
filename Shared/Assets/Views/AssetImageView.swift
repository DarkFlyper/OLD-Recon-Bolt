import SwiftUI

protocol _AssetImageProvider {
	associatedtype Asset: AssetItem & Identifiable
	typealias ID = Asset.ID
	
	static var assetPath: KeyPath<AssetCollection, [ID: Asset]> { get }
}

@dynamicMemberLookup
struct _AssetImageView<Provider: _AssetImageProvider>: View {
	typealias ID = Provider.ID
	typealias Asset = Provider.Asset
	
	@EnvironmentObject
	private var assetManager: AssetManager
	
	let id: ID
	let imageGetter: (Provider.Asset) -> AssetImage?
	
	static subscript(
		dynamicMember keyPath: KeyPath<Asset, AssetImage?>
	) -> (ID) -> Self {
		{ Self(id: $0) { $0[keyPath: keyPath] } }
	}
	
	static subscript(
		dynamicMember keyPath: KeyPath<Asset, AssetImage>
	) -> (ID) -> Self {
		{ Self(id: $0) { $0[keyPath: keyPath] } }
	}
	
	var body: some View {
		if
			let image = assetManager
				.assets?[keyPath: Provider.assetPath][id]
				.flatMap(imageGetter)?
				.imageIfLoaded
		{
			image
				.resizable()
				.scaledToFit()
		} else {
			Color.gray
		}
	}
}
