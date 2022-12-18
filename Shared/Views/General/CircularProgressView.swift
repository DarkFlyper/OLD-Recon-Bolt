import SwiftUI
import ArrayBuilder
import HandyOperators

struct CircularProgressView<Base: View, Background: View>: View {
	typealias Layer = CircularProgressLayer
	
	var lineWidth = 4.0
	@ArrayBuilder<Layer> let layers: () -> [Layer]
	@ViewBuilder let base: () -> Base
	@ViewBuilder let background: () -> Background
	
	var body: some View {
		ZStack {
			let thickerWidth = lineWidth * 1.5
			let thickPadding = thickerWidth * 0.5
			
			let stroke = StrokeStyle(lineWidth: lineWidth, lineCap: .round)
			let thickerStroke = StrokeStyle(lineWidth: thickerWidth, lineCap: .round)
			
			let ring = Circle()
			
			let background = self.background()
				.mask(Circle())
				.padding(-thickPadding)
			
			background
			
			ZStack {
				ZStack {
					background
					base()
				}
				.padding(-thickPadding)
				.mask(ring.stroke(style: stroke))
				
				let layers = layers()
				
				ForEach(layers) { layer in
					if layer.shouldKnockOutSurroundings {
						ZStack {
							layer.arc.stroke(style: thickerStroke)
							layer.arc.stroke(style: stroke)
								.blendMode(.destinationOut)
						}
						.compositingGroup()
						.blendMode(.destinationOut)
					}
					
					layer.arc
						.stroke(layer.color, style: stroke)
						.opacity(layer.opacity)
						.blendMode(layer.blendMode)
				}
			}
			.compositingGroup()
		}
	}
	
	init(
		lineWidth: CGFloat = 4.0,
		@ArrayBuilder<Layer> layers: @escaping () -> [Layer],
		@ViewBuilder base: @escaping () -> Base,
		@ViewBuilder background: @escaping () -> Background
	) {
		self.lineWidth = lineWidth
		self.layers = layers
		self.base = base
		self.background = background
	}
}

extension CircularProgressView where Background == EmptyView {
	init(
		lineWidth: CGFloat = 4.0,
		@ArrayBuilder<Layer> layers: @escaping () -> [Layer],
		@ViewBuilder base: @escaping () -> Base
	) {
		self.lineWidth = lineWidth
		self.layers = layers
		self.base = base
		self.background = { EmptyView() }
	}
}

struct CircularProgressLayer: Identifiable {
	let id = UUID()
	
	var start: CGFloat = 0
	var end: CGFloat
	
	var shouldKnockOutSurroundings = false
	
	var color: Color = .primary
	var opacity: CGFloat = 1
	var blendMode: BlendMode = .normal
	
	var arc: some Shape {
		let crossesZero = start > end
		
		return Circle()
			.rotation(Angle(degrees: -90))
			.trim(from: 0, to: end - start + (crossesZero ? 1 : 0))
			.rotation(Angle(degrees: 360.0 * start))
	}
}

#if DEBUG
struct CircularProgressView_Previews: PreviewProvider {
	static var previews: some View {
		CircularProgressView {
			CircularProgressLayer(
				end: 70 / 100,
				shouldKnockOutSurroundings: true,
				color: .white, opacity: 0.5, blendMode: .plusLighter
			)
		} base: {
			Color.white.opacity(0.25).blendMode(.plusLighter)
		} background: {
			ZStack {
				Color.green
				Color.black.opacity(0.25).blendMode(.plusDarker)
			}
		}
		.padding()
		.previewLayout(.fixed(width: 100, height: 100))
		
		NavigationLink(destination: Color.pink) {
			CircularProgressView(lineWidth: 8) {
				CircularProgressLayer(
					end: 0.8,
					color: .gray
				)
				CircularProgressLayer(
					start: 0.5,
					end: 0.8,
					shouldKnockOutSurroundings: true,
					color: .green
				)
			} base: { Color.gray.opacity(0.25) }
		}
		.padding()
		.previewLayout(.fixed(width: 100, height: 100))
		
		CircularProgressView(lineWidth: 12) {
			CircularProgressLayer(
				end: 0.7,
				shouldKnockOutSurroundings: true,
				opacity: 0.5
			)
			CircularProgressLayer(
				end: 0.5,
				shouldKnockOutSurroundings: true,
				opacity: 0.5
			)
			CircularProgressLayer(
				end: 0.3,
				shouldKnockOutSurroundings: true,
				opacity: 0.5
			)
			CircularProgressLayer(
				start: 0.25, end: 0.75,
				shouldKnockOutSurroundings: false,
				color: .white, opacity: 0.9,
				blendMode: .difference
			)
			CircularProgressLayer(
				start: 0.9,
				end: 0.1,
				shouldKnockOutSurroundings: true,
				color: .green
			)
		} base: {
			Color.red
				.blendMode(.plusLighter)
		}
		.padding()
		.previewLayout(.fixed(width: 200, height: 200))
	}
}
#endif
