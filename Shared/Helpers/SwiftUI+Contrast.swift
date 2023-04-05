import SwiftUI

extension View {
	func foregroundColor(_ color: Color?, adjustedFor colorScheme: ColorScheme) -> some View {
		self
			.foregroundColor(color?.darkened(strength: colorScheme == .light ? 0.3 : 0))
			.brightness(colorScheme == .dark ? 0.1 : 0.0)
	}
}

extension Color {
	func darkened(strength: CGFloat) -> Self {
		guard strength > 0 else { return self }
		let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
		
		let color = cgColor!.converted(to: colorSpace, intent: .defaultIntent, options: nil)!
		
		var components = color.components!
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
		
		return .init(CGColor(colorSpace: colorSpace, components: &components)!)
	}
}
