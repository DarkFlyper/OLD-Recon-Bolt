import SwiftUI

typealias PlayerCardImage = _AssetImageView<_PlayerCardImageProvider>
struct _PlayerCardImageProvider: _AssetImageProvider {
	static let assetPath = \AssetCollection.playerCards
}

#if DEBUG
struct PlayerCardImage_Previews: PreviewProvider {
	private static let id = PlayerCardInfo.ID("893deca1-4123-9c1f-2985-aa9de74cb512")!
	
	static var previews: some View {
		VStack {
			PlayerCardImage.smallArt(id)
			PlayerCardImage.wideArt(id)
			PlayerCardImage.largeArt(id)
		}
		.fixedSize()
		.padding()
		.background(Color(.darkGray))
		.previewLayout(.sizeThatFits)
	}
}
#endif
