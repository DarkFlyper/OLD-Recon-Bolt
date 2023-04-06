import SwiftUI

enum DeepLink {
	typealias Handler = (DeepLink) -> Void
	
	case inApp(InAppLink)
	case widget(WidgetLink)
	
	var shouldAnimate: Bool {
		switch self {
		case .inApp:
			return true
		case .widget:
			return false
		}
	}
}

enum InAppLink {
	case storefront
}

extension EnvironmentValues {
	var deepLink: (InAppLink) -> Void {
		get { self[DeepLinkKey.self] }
		set { self[DeepLinkKey.self] = newValue }
	}
	
	struct DeepLinkKey: EnvironmentKey {
		static var defaultValue: (InAppLink) -> Void = {
			print("no deep link handler installed; ignoring", $0)
		}
	}
}

private enum DeepLinkHandlerKey: PreferenceKey {
	static let defaultValue = HandlerSet()
	
	static func reduce(value: inout HandlerSet, nextValue: () -> HandlerSet) {
		value.merge(nextValue())
	}
	
	struct HandlerSet: Equatable {
		var handlers: [Namespace.ID: DeepLink.Handler] = [:]
		
		mutating func addHandler(for id: Namespace.ID, handler: @escaping DeepLink.Handler) {
			assert(handlers[id] == nil, "attempting to add duplicate handler")
			handlers[id] = handler
		}
		
		mutating func merge(_ other: Self) {
			guard !other.handlers.isEmpty else { return }
			handlers.merge(
				other.handlers,
				uniquingKeysWith: { _, _ in fatalError("attempting to merge duplicate handlers") }
			)
		}
		
		func handle(_ deepLink: DeepLink) {
			for handler in handlers.values {
				handler(deepLink)
			}
		}
		
		static func == (lhs: Self, rhs: Self) -> Bool {
			lhs.handlers.keys == rhs.handlers.keys
		}
	}
}

private struct DeepLinkHandlerModifier: ViewModifier {
	var handler: DeepLink.Handler
	@Namespace private var id
	
	func body(content: Content) -> some View {
		content.transformPreference(DeepLinkHandlerKey.self) {
			$0.addHandler(for: id, handler: handler)
		}
	}
}

extension View {
	func deepLinkHandler(_ handler: @escaping DeepLink.Handler) -> some View {
		modifier(DeepLinkHandlerModifier(handler: handler))
	}
	
	func readingDeepLinkHandler(_ read: @escaping (@escaping DeepLink.Handler) -> Void) -> some View {
		onPreferenceChange(DeepLinkHandlerKey.self) { read($0.handle) }
	}
}
