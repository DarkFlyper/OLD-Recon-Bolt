import SwiftUI

extension View {
	func foregroundColor(_ color: Color?, adjustedFor colorScheme: ColorScheme) -> some View {
		self
			.foregroundColor(color?.darkened(strength: colorScheme == .light ? 0.3 : 0))
			.brightness(colorScheme == .dark ? 0.1 : 0.0)
	}
}

extension CGColorSpace {
	static let sRGBSpace = CGColorSpace(name: sRGB)!
}

extension Color {
	func adjustingSRGBComponents(_ adjust: (inout [CGFloat]) -> Void) -> Self {
		var components = cgColor!.converted(to: .sRGBSpace, intent: .defaultIntent, options: nil)!.components!
		adjust(&components)
		return .init(CGColor(colorSpace: .sRGBSpace, components: &components)!)
	}
	
	func darkened(strength: CGFloat) -> Self {
		guard strength > 0 else { return self }
		
		return adjustingSRGBComponents { components in
			var remaining = strength
			for i in [1, 0, 2] { // darken green, then red, then blue—results in pretty hue-shifting
				if components[i] < remaining {
					remaining -= components[i]
					components[i] = 0
				} else {
					components[i] -= remaining
					break
				}
			}
		}
	}
	
	func opaque() -> Self {
		adjustingSRGBComponents { $0[3] = 1 }
	}
}

extension ShapeStyle where Self == _BlendModeShapeStyle<Color> {
	/// knocks out destination—for best results, combine with ``compositingGroup()``
	static var negative: Self { .init(style: .white, blendMode: .destinationOut) }
}

extension ShapeStyle where Self == _AccentedOrFadedForegroundStyle {
	static var accented: Self { .init(isAccented: true) }
	static var faded: Self { .init(isAccented: false) }
}

// same type so they can be combined via ternary
struct _AccentedOrFadedForegroundStyle: ShapeStyle {
	var isAccented: Bool
	
	func _apply(to shape: inout _ShapeStyle_Shape) {
		if isAccented {
			Color.accentColor._apply(to: &shape)
		} else {
			// quaternary would be perfect for this but for some reason it's more opaque in widgets specifically??
			HierarchicalShapeStyle.primary.opacity(0.1)._apply(to: &shape)
		}
	}
}
