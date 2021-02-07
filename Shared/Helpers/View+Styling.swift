import SwiftUI

extension View {
	func roundedAndStroked(cornerRadius: CGFloat) -> some View {
		roundedAndStroked(cornerRadius: cornerRadius, Color.separator)
	}
	
	func roundedAndStroked<S: ShapeStyle>(cornerRadius: CGFloat, _ style: S) -> some View { self
		.cornerRadius(cornerRadius)
		.overlay(
			RoundedRectangle(cornerRadius: cornerRadius)
				.strokeBorder(style)
		)
	}
	
	/// cancels out the bottom padding automatically added to sheets in macOS
	func withoutSheetBottomPadding() -> some View {
		#if os(macOS)
		return padding(.bottom, -11)
		#else
		return self
		#endif
	}
}
