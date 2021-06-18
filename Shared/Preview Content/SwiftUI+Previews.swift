import SwiftUI

extension View {
	func inEachColorScheme() -> some View {
		ForEach(ColorScheme.allCases, id: \.self, content: preferredColorScheme)
	}
}
