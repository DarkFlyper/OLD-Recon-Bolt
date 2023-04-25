import SwiftUI
import AVKit

struct FullScreenVideoPlayer<Label: View>: View {
	var url: URL
	var aspectRatio: CGFloat = 16/9
	
	@ViewBuilder var label: Label
	
	@State var player: AVPlayer?
	
	var body: some View {
		Button {
			player = .init(url: url)
			player!.play()
		} label: {
			label
		}
		.sheet(item: $player) { player in
			VideoPlayer(player: player)
				.overlay(alignment: .topLeading) {
					Button {
						self.player = nil
					} label: {
						Image(systemName: "xmark.circle.fill")
					}
					.font(.title)
					.preferredColorScheme(.light)
					.foregroundStyle(.regularMaterial)
					.padding()
				}
				.edgesIgnoringSafeArea(.all)
		}
	}
}

extension AVPlayer: Identifiable {}
