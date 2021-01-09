import SwiftUI

extension View {
	func roundedAndStroked(cornerRadius: CGFloat) -> some View {
		#if os(macOS)
		return roundedAndStroked(cornerRadius: cornerRadius, Color(.separatorColor))
		#else
		return roundedAndStroked(cornerRadius: cornerRadius, Color(.separator))
		#endif
	}
	
	func roundedAndStroked<S: ShapeStyle>(cornerRadius: CGFloat, _ style: S) -> some View {
		self
			.cornerRadius(cornerRadius)
			.overlay(
				RoundedRectangle(cornerRadius: cornerRadius)
					.strokeBorder(style)
			)
	}
	
	func withoutSheetBottomPadding() -> some View {
		#if os(macOS)
		return padding(.bottom, -11)
		#else
		return self
		#endif
	}
}
