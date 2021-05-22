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

extension Image {
	init?(data: Data) {
		print("making image from \(data)")
		#if os(macOS)
		guard let image = NSImage(data: data) else { return nil }
		self.init(nsImage: image)
		#else
		guard let image = UIImage(data: data) else { return nil }
		self.init(uiImage: image)
		#endif
	}
	
	init?(at url: URL) {
		print("making image at \(url)")
		#if os(macOS)
		guard let image = NSImage(contentsOf: url) else { return nil }
		self.init(nsImage: image)
		#else
		guard let image = UIImage(contentsOfFile: url.path) else { return nil }
		self.init(uiImage: image)
		#endif
	}
}
