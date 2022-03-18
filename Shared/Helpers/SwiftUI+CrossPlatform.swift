import SwiftUI

extension Color {
	static let separator = Color(.separator)
}

extension View {
	@ViewBuilder
	func withToolbar(allowLargeTitles: Bool = true) -> some View {
		NavigationView {
			self.if(!allowLargeTitles) {
				$0.navigationBarTitleDisplayMode(.inline)
			}
		}
		.navigationViewStyle(.stack)
	}
}

extension Image {
	init?(at url: URL) {
		guard let image = UIImage(contentsOfFile: url.path) else { return nil }
		self.init(uiImage: image)
	}
}
