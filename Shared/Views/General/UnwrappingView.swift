import SwiftUI

struct UnwrappingView<Value, Content: View>: View {
	let value: Value?
	let placeholder: LocalizedStringKey
	@ViewBuilder var content: (Value) -> Content
	
	var body: some View {
		if let value = value {
			content(value)
		} else {
			Text(placeholder)
				.foregroundColor(.secondary)
				.frame(maxWidth: .infinity, maxHeight: .infinity)
		}
	}
}

struct AssetsUnwrappingView<Content: View>: View {
	@ViewBuilder var content: (_ assets: AssetCollection) -> Content
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		UnwrappingView(value: assets, placeholder: "Assets not loaded!", content: content)
	}
}
