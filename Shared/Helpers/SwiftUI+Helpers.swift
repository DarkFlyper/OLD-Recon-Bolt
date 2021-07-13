import SwiftUI

#if DEBUG
var isInSwiftUIPreview: Bool {
	ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}
#else
let isInSwiftUIPreview = false
#endif

extension ShapeStyle where Self == Color {
	// not sure why apple missed this tbh
	static var accentColor: Self { Color.accentColor }
}

extension Gradient {
	init(_ color: Color, opacities: [Double] = [1, 0]) {
		self.init(colors: opacities.map(color.opacity))
	}
}

extension View {
	func measuring<Key: PreferenceKey>(
		_ path: KeyPath<CGSize, CGFloat>, as key: Key.Type
	) -> some View where Key.Value == CGFloat {
		modifier(Measuring<Key>(measurePath: path))
	}
}

struct Measuring<Key: PreferenceKey>: ViewModifier where Key.Value == CGFloat {
	let measurePath: KeyPath<CGSize, CGFloat>
	
	@State private var value = 0.0
	
	func body(content: Content) -> some View {
		content
			.measured { value = $0[keyPath: measurePath] }
			.preference(key: Key.self, value: value)
	}
}

extension Binding {
	/// SwiftUI will sometimes decide to recompute view bodies for optional bindings that are no longer valid.
	/// This works around that by simply returning the last non-nil value instead.
	init?(optionalWorkaround base: Binding<Value?>) {
		guard var lastValue = base.wrappedValue else { return nil }
		self.init(
			get: {
				if let value = base.wrappedValue {
					lastValue = value
					return value
				} else {
					print("accessing nil binding; providing last non-nil value")
					return lastValue
				}
			},
			set: { base.wrappedValue = $0 }
		)
	}
}
