import SwiftUI
import SwiftUIMissingPieces

#if DEBUG
var isInSwiftUIPreview: Bool {
	#if WIDGETS
	// i'm so sorry
	ProcessInfo.processInfo.environment["HOME"]?.contains("Previews") == true
	#else
	ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
	#endif
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
	func frame(size: CGFloat, alignment: Alignment = .center) -> some View {
		frame(width: size, height: size, alignment: alignment)
	}
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

extension View {
	@ViewBuilder
	func aligningListRowSeparator() -> some View {
		if #available(iOS 16.0, *) {
			alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
		} else {
			self
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
	
	/// - note: this cannot be set back to true when currently false
	func isSome<T>() -> Binding<Bool> where Value == T? {
		.init(
			get: { wrappedValue != nil },
			set: { wrappedValue = $0 ? wrappedValue : nil }
		)
	}
	
	func equals<T: Equatable>(_ value: T) -> Binding<Bool> where Value == T? {
		.init(
			get: { wrappedValue == value },
			set: { isEqual in
				guard (wrappedValue == value) != isEqual else { return }
				wrappedValue = isEqual ? value : nil
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

extension View {
	func placeholder(`if` isPlaceholder: Bool) -> some View {
		redacted(reason: isPlaceholder ? .placeholder : [])
	}
}

/// button that looks like a ``NavigationLink``
struct NavigationButton<Label: View>: View {
	var action: () -> Void
	@ViewBuilder var label: Label
	
	var body: some View {
		Button(action: action) {
			NavigationLink {} label: {
				HStack {
					label
				}
			}
			.tint(.primary)
		}
	}
}
