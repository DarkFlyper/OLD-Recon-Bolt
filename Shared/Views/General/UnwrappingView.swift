import SwiftUI

struct UnwrappingView<Value, Content: View>: View {
	let value: Value?
	let placeholder: Text
	@ViewBuilder var content: (Value) -> Content
	
	init(value: Value?, placeholder: LocalizedStringKey, @ViewBuilder content: @escaping (Value) -> Content) {
		self.init(value: value, placeholder: Text(placeholder), content: content)
	}
	
	init(value: Value?, placeholder: Text, @ViewBuilder content: @escaping (Value) -> Content) {
		self.value = value
		self.placeholder = placeholder
		self.content = content
	}
	
	init(value: Value?, placeholder: Text) where Value == String, Content == Text {
		self.init(value: value, placeholder: placeholder) { Text($0) }
	}
	
	var body: some View {
		if let value {
			content(value)
		} else {
			placeholder
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
