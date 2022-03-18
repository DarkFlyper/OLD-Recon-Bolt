import SwiftUI

extension View {
	func roundedAndStroked(cornerRadius: CGFloat) -> some View {
		roundedAndStroked(Color.separator, cornerRadius: cornerRadius)
	}
	
	@ViewBuilder
	func roundedAndStroked<S: ShapeStyle>(
		_ style: S,
		cornerRadius: CGFloat,
		lineWidth: CGFloat = 1,
		shouldInset: Bool = false
	) -> some View {
		let difference = shouldInset ? lineWidth : 0
		
		self
			.padding(difference)
			.cornerRadius(cornerRadius - difference)
			.overlay(
				RoundedRectangle(cornerRadius: cornerRadius)
					.strokeBorder(style, lineWidth: lineWidth)
			)
	}
}
