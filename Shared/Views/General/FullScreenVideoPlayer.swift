import SwiftUI
import AVKit

typealias AVPlayer = AVKit.AVPlayer

// had to move away from having a self-contained button because rotating to landscape could make a list unload it and stop the sheet

extension View {
	func fullScreenVideoPlayer(player: Binding<AVPlayer?>) -> some View {
		modifier(PlayerModifier(player: player))
	}
}

private struct PlayerModifier: ViewModifier {
	@Binding var player: AVPlayer?
	
	func body(content: Content) -> some View {
		content.sheet(item: $player) { player in
			VideoPlayer(player: player)
				.overlay(alignment: .topLeading) {
					Button {
						self.player = nil
					} label: {
						Image(systemName: "xmark.circle.fill")
							.padding()
					}
					.font(.title)
					.preferredColorScheme(.light)
					.foregroundStyle(.regularMaterial)
				}
				.edgesIgnoringSafeArea(.all)
		}
	}
}

extension AVPlayer: Identifiable {}

extension AVPlayer {
	convenience init(url: URL, autoplay: Bool = false) {
		self.init(url: url)
		if autoplay {
			play()
		}
	}
}
