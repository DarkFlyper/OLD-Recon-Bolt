import SwiftUI

struct PrettyTextFieldStyle: TextFieldStyle {
	@ViewBuilder
	func _body(configuration: TextField<_Label>) -> some View {
		configuration
			.padding(.horizontal, 1) // looks weird otherwise
			.padding(8)
			.background(Color(.secondarySystemGroupedBackground))
			.roundedAndStroked(cornerRadius: 4)
	}
}
