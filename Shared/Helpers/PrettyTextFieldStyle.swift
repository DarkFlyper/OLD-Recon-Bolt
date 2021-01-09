import SwiftUI

struct PrettyTextFieldStyle: TextFieldStyle {
	#if os(macOS)
	func _body(configuration: TextField<_Label>) -> some View {
		configuration
			.textFieldStyle(PlainTextFieldStyle()) // i feel like this shouldn't be necessary, but we're already hacking anyway
			.padding(.horizontal, 1) // looks weird otherwise
			.padding(4)
			.background(Color(.textBackgroundColor))
			.roundedAndStroked(cornerRadius: 4, Color(.separatorColor))
	}
	#else
	func _body(configuration: TextField<_Label>) -> some View {
		configuration
			.padding(.horizontal, 1) // looks weird otherwise
			.padding(8)
			.background(Color(.tertiarySystemBackground))
			.roundedAndStroked(cornerRadius: 4, Color(.separator))
	}
	#endif
}
