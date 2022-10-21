import SwiftUI
import ValorantAPI

typealias WeaponImage = AssetImageView<_WeaponImageProvider>
struct _WeaponImageProvider: AssetImageProvider {
	static let assetPath = \AssetCollection.weapons
}

extension WeaponImage {
	static func killStreamIcon(_ id: Weapon.ID) -> Self {
		Self(id: id, renderingMode: .template, shouldLoadImmediately: true, getImage: \.killStreamIcon)
	}
	
	static func displayIcon(_ id: Weapon.ID) -> Self {
		Self(id: id, getImage: \.displayIcon)
	}
	
	static func shopImage(_ id: Weapon.ID) -> Self {
		Self(id: id, getImage: \.shopData?.image)
	}
}

#if DEBUG
struct WeaponImage_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			WeaponImage.killStreamIcon(.operator)
				.padding()
		}
		.previewLayout(.sizeThatFits)
	}
}
#endif
