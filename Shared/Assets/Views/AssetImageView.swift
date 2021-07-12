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
	
	@Environment(\.assets) private var assets
	
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
		let assetImage = assets?[keyPath: Provider.assetPath][id]
			.flatMap(imageGetter)
		
		if let assetImage = assetImage {
			assetImage.imageOrPlaceholder()
		} else {
			Color.gray
		}
	}
}
