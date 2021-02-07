import SwiftUI

#if os(macOS)
typealias PrettyListStyle = InsetListStyle
#else
typealias PrettyListStyle = InsetGroupedListStyle
#endif

struct PrettyTextFieldStyle: TextFieldStyle {
	@ViewBuilder
	func _body(configuration: TextField<_Label>) -> some View {
		#if os(macOS)
		configuration
			.textFieldStyle(PlainTextFieldStyle()) // i feel like this shouldn't be necessary, but we're already hacking anyway
			.padding(.horizontal, 1) // looks weird otherwise
			.padding(4)
			.background(Color(.textBackgroundColor))
			.roundedAndStroked(cornerRadius: 4)
		#else
		configuration
			.padding(.horizontal, 1) // looks weird otherwise
			.padding(8)
			.background(Color(.tertiarySystemBackground))
			.roundedAndStroked(cornerRadius: 4)
		#endif
	}
}

struct UnifiedLinkButtonStyle: PrimitiveButtonStyle {
	@ViewBuilder
	func makeBody(configuration: Configuration) -> some View {
		#if os(macOS)
		Button(configuration)
			.buttonStyle(LinkButtonStyle())
			.foregroundColor(.accentColor)
		#else
		Button(configuration)
		#endif
	}
}
