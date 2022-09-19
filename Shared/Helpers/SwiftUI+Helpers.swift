import SwiftUI

#if DEBUG
var isInSwiftUIPreview: Bool {
	ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}
#else
let isInSwiftUIPreview = false
#endif

extension Color {
	static let separator = Color(.separator)
	static let groupedBackground = Self(.systemGroupedBackground)
	static let secondaryGroupedBackground = Self(.secondarySystemGroupedBackground)
	static let tertiaryGroupedBackground = Self(.tertiarySystemGroupedBackground)
	static let valorantBlue = Color("Valorant Blue")
	static let valorantRed = Color("Valorant Red")
	static let valorantSelf = Color("Valorant Self")
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

private struct Measuring<Key: PreferenceKey>: ViewModifier where Key.Value == CGFloat {
	let measurePath: KeyPath<CGSize, CGFloat>
	
	@State private var value = 0.0
	
	func body(content: Content) -> some View {
		content
			.measured { value = $0[keyPath: measurePath] }
			.preference(key: Key.self, value: value)
	}
}

extension View {
	func onSceneActivation(perform task: @escaping () async -> Void) -> some View {
		modifier(OnSceneActivationModifier(task: task))
	}
}

private struct OnSceneActivationModifier: ViewModifier {
	var task: () async -> Void
	
	@Environment(\.scenePhase) private var scenePhase
	
	func body(content: Content) -> some View {
		content
			.task(id: scenePhase) {
				guard scenePhase == .active else { return }
				await task()
			}
	}
}

extension HorizontalAlignment {
	static var compatibleListRowSeparatorLeading: Self {
		if #available(iOS 16.0, *) {
			return .listRowSeparatorLeading
		} else {
			struct Dummy: AlignmentID {
				static func defaultValue(in context: ViewDimensions) -> CGFloat { context[.leading] }
			}
			return .init(Dummy.self)
		}
	}
}

extension Binding {
	func contains<T: Hashable>(_ value: T) -> Binding<Bool> where Value == Set<T> {
		.init(
			get: { wrappedValue.contains(value) },
			set: {
				if $0 {
					wrappedValue.insert(value)
				} else {
					wrappedValue.remove(value)
				}
			}
		)
	}
}

extension View {
	/// ``sheet(item:onDismiss:content:)`` nils out the binding before calling onDismiss, but sometimes you still want to access it.
	func sheet<Item, Content>(
		caching item: Binding<Item?>,
		content: @escaping (Item) -> Content,
		onDismiss: @escaping (Item) -> Void
	) -> some View where Item: Identifiable, Content: View {
		let cached = item.wrappedValue
		return sheet(
			item: item,
			onDismiss: { onDismiss(cached!) },
			content: content
		)
	}
}
