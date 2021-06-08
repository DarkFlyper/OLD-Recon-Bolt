import SwiftUI

extension View {
	func dynamicallyStroked(
		radius: CGFloat,
		color: Color = .primary,
		blendMode: BlendMode = .normal,
		avoidClipping: Bool = false
	) -> some View {
		DynamicallyStroked(
			content: self,
			radius: radius,
			color: color,
			blendMode: blendMode,
			avoidClipping: avoidClipping
		)
	}
}

private struct DynamicallyStroked<Content: View>: View {
	let content: Content
	let radius: CGFloat
	let color: Color
	let blendMode: BlendMode
	let avoidClipping: Bool
	
	var body: some View {
		content.background(
			content
				.compositingGroup()
				.brightness(1)
				.shadow(color: .white, radius: radius)
				.brightness(Double(pow(radius, 0.4))) // this exponent seems to make it grow appropriately
				// FIXME: this breaks images but is necessary to avoid clipping
				.padding(avoidClipping ? radius + 1 : 0)
				.background(Color.black)
				.compositingGroup()
				.contrast(100)
				.blur(radius: 0.2, opaque: true) // slight anti-aliasing
				.luminanceToAlpha()
				.brightness(1)
				.colorMultiply(color)
				.drawingGroup()
				.blendMode(blendMode)
		)
	}
}

#if DEBUG
struct DynamicallyStroked_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			ForEach([1, 2, 8, 40] as [CGFloat], id: \.self) { radius in
				Circle()
					.fill(Color.green)
					.frame(width: 100, height: 100)
					.dynamicallyStroked(radius: radius, color: .blue)
			}
			
			Image(systemName: "applelogo")
				.font(.system(size: 80))
				.dynamicallyStroked(radius: 4, color: .white)
			
			AgentImage.displayIcon(AgentImage_Previews.agentID)
				.frame(width: 80)
				.dynamicallyStroked(radius: 4, color: .white)
				.withPreviewAssets()
		}
		.padding(50)
		.background(Color.gray)
		.fixedSize()
		.previewLayout(.sizeThatFits)
	}
}
#endif
