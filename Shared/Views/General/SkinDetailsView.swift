import SwiftUI

struct SkinDetailsView: View {
	var skin: WeaponSkin
	
	var body: some View {
		List {
			Section { chromas() } header: {
				Text("Color Variants", comment: "Skin Details: section")
			}
			Section { levels() } header: {
				Text("Skin Levels", comment: "Skin Details: section")
			}
		}
		.navigationTitle(skin.displayName)
		.navigationBarTitleDisplayMode(.inline)
	}
	
	func chromas() -> some View {
		ForEach(skin.chromas) { chroma in
			chroma.fullRender.view()
				.frame(maxHeight: 80)
				.frame(maxWidth: .infinity)
				.padding()
				.overlay(alignment: .bottomTrailing) {
					if let videoURL = chroma.streamedVideo {
						FullScreenVideoPlayer(url: videoURL) {
							Image(systemName: "play.circle")
						}
					}
				}
		}
	}
	
	func levels() -> some View {
		ForEach(skin.levels.indexed(), id: \.element.id) { index, level in
			HStack {
				Text(String(localized: "Skin Level %lld", defaultValue: "Level \(index + 1)", comment: "Skin Details: level name"))
				
				Spacer()
				
				if let item = level.levelItem {
					Text(item.description)
						.foregroundColor(.secondary)
				}
				
				if let videoURL = level.streamedVideo {
					FullScreenVideoPlayer(url: videoURL) {
						Image(systemName: "play.circle")
					}
				}
			}
			.aligningListRowSeparator()
		}
	}
}

struct SkinDetailsView_Previews: PreviewProvider, PreviewProviderWithAssets {
	static func previews(assets: AssetCollection) -> some View {
		SkinDetailsView(skin: assets.weapons[.phantom]!.skins[1])
			.withToolbar()
    }
}
