import SwiftUI
import ValorantAPI

struct RefreshableBox<Content: View>: View {
	var title: LocalizedStringKey
	@Binding var isExpanded: Bool
	@ViewBuilder var content: () -> Content
	var refresh: (ValorantClient) async throws -> Void
	
	@Environment(\.valorantLoad) private var load
	
	var body: some View {
		VStack(spacing: 0) {
			HStack {
				ExpandButton(isExpanded: $isExpanded) {
					HStack {
						Text(title)
						
						Spacer()
					}
				}
				.padding()
				
				AsyncButton(action: doRefresh) {
					Image(systemName: "arrow.clockwise")
						.padding()
				}
			}
			.font(.title2.weight(.semibold))
			
			if isExpanded {
				Divider()
				
				content()
					.groupBoxStyle(NestedGroupBoxStyle())
			}
		}
		.background(Color.secondaryGroupedBackground)
		.cornerRadius(20)
		.task(doRefresh)
		.onSceneActivation(perform: doRefresh)
	}
	
	@Sendable
	private func doRefresh() async {
		await load(refresh)
	}
	
	#if DEBUG
	func forPreviews() -> some View {
		self.padding()
			.background(Color.groupedBackground)
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
			.background(Color.tertiaryGroupedBackground)
			.cornerRadius(8)
		}
	}
}
