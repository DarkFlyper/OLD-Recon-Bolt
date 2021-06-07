import SwiftUI

extension View {
	func inEachColorScheme() -> some View {
		ForEach(ColorScheme.allCases, id: \.self, content: preferredColorScheme)
	}
	
	func withMockValorantLoadManager() -> some View {
		withLoadManager(ValorantLoadManager(dataStore: PreviewData.mockDataStore))
	}
	
	func withPreviewAssets() -> some View {
		environmentObject(AssetManager.forPreviews)
	}
}
