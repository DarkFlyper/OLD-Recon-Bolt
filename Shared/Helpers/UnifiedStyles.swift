import SwiftUI

struct PrettyTextFieldStyle: TextFieldStyle {
	@ViewBuilder
	func _body(configuration: TextField<_Label>) -> some View {
		configuration
			.padding(.horizontal, 1) // looks weird otherwise
#if os(macOS)
			.textFieldStyle(.plain) // i feel like this shouldn't be necessary, but we're already hacking anyway
			.padding(4)
			.background(Color(.textBackgroundColor))
#else
			.padding(8)
			.background(Color(.tertiarySystemBackground))
#endif
			.roundedAndStroked(cornerRadius: 4)
	}
}
