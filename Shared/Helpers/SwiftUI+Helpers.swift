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

/// Navigation Links turn gray when used outside a navigation view, which often happens in SwiftUI previews. This works around that, making them look enabled anyway.
extension PrimitiveButtonStyle where Self == _NavigationLinkPreviewButtonStyle {
	static var navigationLinkPreview: _NavigationLinkPreviewButtonStyle { .init() }
}

struct _NavigationLinkPreviewButtonStyle: PrimitiveButtonStyle {
	func makeBody(configuration: PrimitiveButtonStyleConfiguration) -> some View {
		Button(role: configuration.role, action: configuration.trigger) {
			configuration.label
		}
		.buttonStyle(.plain)
		.environment(\.isEnabled, true)
	}
}
