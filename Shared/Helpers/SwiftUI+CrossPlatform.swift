import SwiftUI

extension Color {
	#if os(macOS)
	static let separator = Color(.separatorColor)
	#else
	static let separator = Color(.separator)
	#endif
}

extension View {
	@ViewBuilder
	func withToolbar() -> some View {
		#if os(macOS)
		self
		#else
		NavigationView { self }
			.navigationViewStyle(StackNavigationViewStyle())
		#endif
	}
}

extension ToolbarItemPlacement {
	#if os(macOS)
	static let leading = automatic
	static let trailing = automatic
	#else
	static let leading = navigationBarLeading
	static let trailing = navigationBarTrailing
	#endif
}
