import SwiftUI
import CGeometry

struct Lightbox<Content: View>: View {
	@Environment(\.presentationMode) @Binding var presentationMode
	
	@ViewBuilder let content: () -> Content
	let minZoomScale = 1.0
	let maxZoomScale = 10.0
	
	@State private var zoomScaleBase = 1.0
	@GestureState private var zoomScaleDelta = 1.0
	private var zoomScale: CGFloat { zoomScaleBase * zoomScaleDelta }
	@State private var contentSize = CGSize(width: 1, height: 1)
	
	var body: some View {
		ZStack {
			GeometryReader { geometry in
				ScrollView([.horizontal, .vertical], showsIndicators: false) {
					let contentScale = (geometry.size / contentSize).min * zoomScale
					let scaledContentSize = contentSize * contentScale
					content()
						.fixedSize()
						.measured { contentSize = $0 }
						.scaleEffect(contentScale)
						.frame(
							width: scaledContentSize.width,
							height: scaledContentSize.height,
							alignment: .center
						)
				}
				.animation(.easeOut(duration: 0.1), value: zoomScale)
				.transition(.scale)
			}
			
			Button { presentationMode.dismiss() } label: {
				Image(systemName: "xmark")
					.foregroundColor(.white)
					.padding()
			}
			.shadow(radius: 2)
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
		}
		.background(Color.black.edgesIgnoringSafeArea(.all))
		.transition(.opacity)
		.gesture(
			MagnificationGesture(minimumScaleDelta: 0)
				.updating($zoomScaleDelta) { scale, zoomScaleDelta, transaction in
					print("\t\(scale)")
					transaction.disablesAnimations = true
					zoomScaleDelta = scale
				}
				.onEnded { scale in
					let clamped = max(
						minZoomScale,
						min(
							maxZoomScale,
							scale * zoomScaleBase
						)
					)
					print("delta:", zoomScaleDelta)
					print("\(clamped)x (\(scale))")
					zoomScaleBase = clamped
				}
		)
		// double tap to zoom
		.onTapGesture(count: 2) {
			withAnimation(.easeInOut(duration: 0.25)) {
				// TODO: ideally, we'd zoom in on where the tap was rather than just centered
				zoomScaleBase = zoomScaleBase > 1 ? 1 : 2
			}
		}
		.statusBar(hidden: true)
	}
}

#if DEBUG
import ValorantAPI

struct Lightbox_Previews: PreviewProvider {
	static var previews: some View {
		Lightbox {
			MapImage.displayIcon(.breeze)
		}
	}
}
#endif
