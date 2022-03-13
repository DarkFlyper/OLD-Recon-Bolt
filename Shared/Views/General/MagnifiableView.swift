import SwiftUI
import SwiftUIMissingPieces
import CGeometry

struct MagnifiableView<Content: View>: View {
	var magnificationScale = 3.0
	@ViewBuilder var content: () -> Content
	var onMagnifyToggle: ((Bool) -> Void)?
	
	@State private var contentSize = CGSize.zero
	
	@GestureState private var magnificationLocation: CGPoint?
	
	@AppStorage("MagnifiableView.useNaturalDragging")
	private var useNaturalDragging = false
	
	private var isMagnifying: Bool {
		magnificationLocation != nil
	}
	
	var body: some View {
		let coordSpaceName = "scale-independent"
		
		ZStack(alignment: .bottomTrailing) {
			content()
				.measured { contentSize = $0 }
				// there is some tolerance here that i'd rather avoid—not least to avoid interacting with the image when swiping back in the navigation stack
				.contentShape(Rectangle().inset(by: 32))
				.gesture(
					DragGesture(minimumDistance: 0, coordinateSpace: .named(coordSpaceName))
						.updating($magnificationLocation) { value, location, _ in
							location = useNaturalDragging
							? value.startLocation - CGVector(value.translation) / (magnificationScale - 1)
							: value.location
						}
				)
				.onChange(of: isMagnifying) { onMagnifyToggle?($0) }
			
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
		.coordinateSpace(name: coordSpaceName)
		.animation(.easeOut(duration: 0.1), value: isMagnifying)
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
