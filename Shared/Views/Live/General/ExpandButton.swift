import SwiftUI

struct ExpandButton<Label: View>: View {
	@Binding var isExpanded: Bool
	@ViewBuilder var label: Label
	
	var body: some View {
		Button {
			withAnimation {
				isExpanded.toggle()
			}
		} label: {
			HStack {
				Image(systemName: "chevron.down")
					.rotationEffect(.degrees(isExpanded ? 0 : -90))
				
				label.tint(.primary)
			}
		}
	}
}
