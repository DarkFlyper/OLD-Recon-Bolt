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
				.overlay(alignment: .topLeading) { SheetCloseButton() }
				.edgesIgnoringSafeArea(.all)
		}
		.onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { _ in
			player = nil
		}
	}
}

struct AssetImageLightbox: View {
	var images: [AssetImage]
	
	var body: some View {
		TabView {
			ForEach(images, id: \.self) { image in
				image.view(maxScale: 1)
					.frame(maxWidth: .infinity, maxHeight: .infinity)
					.edgesIgnoringSafeArea(.bottom) // can't seem to make this work but eh
			}
		}
		.tabViewStyle(.page)
		.overlay(alignment: .topLeading) { SheetCloseButton() }
		.background(Color.black)
	}
}

extension AssetImageLightbox {
	init(images: [AssetImage?]) {
		self.init(images: images.compactMap { $0 })
	}
}

struct AssetImageCollection: Identifiable {
	let id = UUID()
	var images: [AssetImage?]
}

extension AssetImageCollection: ExpressibleByArrayLiteral {
	init(arrayLiteral elements: AssetImage?...) {
		self.init(images: elements)
	}
}

extension View {
	func lightbox(for image: Binding<AssetImage?>) -> some View {
		sheet(item: image) { image in
			AssetImageLightbox(images: [image])
		}
	}
	
	func lightbox(for collection: Binding<AssetImageCollection?>) -> some View {
		sheet(item: collection) { collection in
			AssetImageLightbox(images: collection.images)
		}
	}
}

struct SheetCloseButton: View {
	@Environment(\.dismiss) private var dismiss
	
	var body: some View {
		Button {
			dismiss()
		} label: {
			Image(systemName: "xmark.circle.fill")
				.padding()
		}
		.font(.title)
		.preferredColorScheme(.light)
		.foregroundStyle(.regularMaterial) // to be used on dark backgrounds
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
