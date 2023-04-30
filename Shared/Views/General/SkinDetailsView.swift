import SwiftUI

struct SkinDetailsView: View {
	var skin: WeaponSkin
	
	@State var videoPlayer: AVPlayer?
	
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
		.fullScreenVideoPlayer(player: $videoPlayer)
	}
	
	func chromas() -> some View {
		ForEach(skin.chromas) { chroma in
			chroma.fullRender.view()
				.frame(maxHeight: 80)
				.frame(maxWidth: .infinity)
				.padding()
				.overlay(alignment: .bottomTrailing) {
					videoButton(for: chroma.streamedVideo)
				}
		}
	}
	
	func levels() -> some View {
		ForEach(skin.levels.indexed(), id: \.element.id) { index, level in
			HStack {
				Text(String(localized: "Skin Level %lld", defaultValue: "Level \(index + 1)", comment: "Skin Details: level name"))
				
				Spacer()
				
				if let item = level.levelItem {
					item.description
						.foregroundColor(.secondary)
				}
				
				videoButton(for: level.streamedVideo)
			}
			.aligningListRowSeparator()
		}
	}
	
	@ViewBuilder
	func videoButton(for url: URL?) -> some View {
		if let url {
			Button {
				videoPlayer = .init(url: url, autoplay: true)
			} label: {
				Image(systemName: "play.circle")
			}
		}
	}
}

#if DEBUG
struct SkinDetailsView_Previews: PreviewProvider, PreviewProviderWithAssets {
	static func previews(assets: AssetCollection) -> some View {
		SkinDetailsView(skin: assets.weapons[.phantom]!.skins[1])
			.withToolbar()
    }
}
#endif
