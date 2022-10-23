import SwiftUI

extension TextFieldStyle where Self == _PrettyTextFieldStyle {
	static var pretty: _PrettyTextFieldStyle { .init() }
}

struct _PrettyTextFieldStyle: TextFieldStyle {
	@ViewBuilder
	func _body(configuration: TextField<_Label>) -> some View {
		configuration
			.padding(.horizontal, 1) // looks weird otherwise
			.padding(8)
			.background(Color.secondaryGroupedBackground)
			.roundedAndStroked(cornerRadius: 4)
	}
}

#if DEBUG
extension PrimitiveButtonStyle where Self == _NavigationLinkPreviewButtonStyle {
	/// Navigation Links turn gray when used outside a navigation view, which often happens in SwiftUI previews. This works around that, making them look enabled anyway.
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
#endif
