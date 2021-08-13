import SwiftUI
import SwiftUIMissingPieces
import CGeometry

struct MagnifiableView<Content: View>: View {
	@ViewBuilder var content: () -> Content
	
	@State private var contentSize = CGSize.zero
	
	@GestureState private var magnificationLocation: CGPoint?
	
	@AppStorage("MagnifiableView.useNaturalDragging")
	private var useNaturalDragging = false
	
	private var isMagnifying: Bool {
		magnificationLocation != nil
	}
	
	var body: some View {
		let magnificationScale = 3.0
		
		ZStack(alignment: .bottomTrailing) {
			content()
			
			Button { useNaturalDragging.toggle() } label: {
				Image(
					systemName: useNaturalDragging
						? "arrow.left.arrow.right.circle.fill"
						: "arrow.left.arrow.right.circle"
				)
				.padding()
				.font(.title3)
			}
			.opacity(isMagnifying ? 0 : 1)
		}
		.scaleEffect(
			isMagnifying ? magnificationScale : 1,
			anchor: magnificationLocation
				.map { UnitPoint($0, in: contentSize) }
				?? .center
		)
		.animation(.easeOut(duration: 0.1), value: isMagnifying)
		.measured { contentSize = $0 }
		.gesture(
			DragGesture(minimumDistance: 0, coordinateSpace: .local)
				.updating($magnificationLocation) { value, location, _ in
					location = useNaturalDragging
						? value.startLocation - CGVector(value.translation) / (magnificationScale - 1)
						: value.location
				}
		)
	}
}

#if DEBUG
struct MagnifiableView_Previews: PreviewProvider {
    static var previews: some View {
		MagnifiableView {
			Image(systemName: "doc.richtext")
				.background(.quaternary)
		}
		.font(.system(size: 320))
	}
}
#endif

private extension UnitPoint {
	init(_ point: CGPoint, in size: CGSize) {
		self.init(
			x: point.x / size.width,
			y: point.y / size.height
		)
	}
}
