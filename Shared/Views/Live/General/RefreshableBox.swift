import SwiftUI

struct RefreshableBox<Content: View>: View {
	var title: String
	var refreshAction: () async -> Void
	@ViewBuilder var content: () -> Content
	
	var body: some View {
		VStack(spacing: 0) {
			HStack {
				Text(title)
					.font(.title2)
					.fontWeight(.semibold)
				
				Spacer()
				
				AsyncButton(action: refreshAction) {
					Image(systemName: "arrow.clockwise")
				}
			}
			.padding()
			
			content()
				.groupBoxStyle(NestedGroupBoxStyle())
		}
		.background(Color(.tertiarySystemBackground))
		.cornerRadius(20)
	}
	
	#if DEBUG
	func forPreviews() -> some View {
		self.padding()
			.background(Color(.systemGroupedBackground))
			.shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
			.previewLayout(.sizeThatFits)
	}
	#endif
	
	private struct NestedGroupBoxStyle: GroupBoxStyle {
		func makeBody(configuration: Configuration) -> some View {
			VStack(spacing: 16) {
				configuration.content
			}
			.frame(maxWidth: .infinity)
			.padding()
			.background(Color(.secondarySystemBackground))
			.cornerRadius(8)
		}
	}
}
