import SwiftUI

extension View {
	func inEachColorScheme() -> some View {
		ForEach(ColorScheme.allCases, id: \.self, content: preferredColorScheme)
	}
}

extension View {
	func withMockData() -> some View {
		self
			.withValorantLoadManager()
			.environmentObject(ClientDataStore(keychain: MockKeychain(), for: MockClientData.self))
			.environmentObject(AssetManager.forPreviews)
	}
}
