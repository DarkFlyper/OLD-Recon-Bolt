import SwiftUI
import ValorantAPI

typealias PlayerCardImage = AssetImageView<_PlayerCardImageProvider>
struct _PlayerCardImageProvider: AssetImageProvider {
	static let assetPath = \AssetCollection.playerCards
}

extension PlayerCardImage {
	static func small(_ id: PlayerCard.ID) -> Self {
		Self(id: id, getImage: \.smallArt)
	}
	
	static func large(_ id: PlayerCard.ID) -> Self {
		Self(id: id, getImage: \.largeArt)
	}
	
	static func wide(_ id: PlayerCard.ID) -> Self {
		Self(id: id, getImage: \.wideArt)
	}
}

#if DEBUG
struct PlayerCardImage_Previews: PreviewProvider {
	private static let id = PlayerCardInfo.ID("893deca1-4123-9c1f-2985-aa9de74cb512")!
	
	static var previews: some View {
		VStack {
			PlayerCardImage.small(id)
			PlayerCardImage.wide(id)
			PlayerCardImage.large(id)
		}
		.fixedSize()
		.padding()
		.background(Color(.darkGray))
		.previewLayout(.sizeThatFits)
	}
}
#endif
