import SwiftUI
import ValorantAPI

struct RefreshableBox<Content: View>: View {
	var title: String
	@ViewBuilder var content: () -> Content
	var refresh: (ValorantClient) async throws -> Void
	// cheeky way of differentiating between these boxes without needing a custom initializer
	@AppStorage("\(Self.self).isExpanded") var isExpanded = true
	
	@Environment(\.valorantLoad) private var load
	
	var body: some View {
		VStack(spacing: 0) {
			HStack {
				expandButton
				
				AsyncButton(action: doRefresh) {
					Image(systemName: "arrow.clockwise")
				}
			}
			.padding()
			
			if isExpanded {
				content()
					.groupBoxStyle(NestedGroupBoxStyle())
			}
		}
		.background(Color.secondaryGroupedBackground)
		.cornerRadius(20)
		.task(doRefresh)
		.onSceneActivation(perform: doRefresh)
	}
	
	var expandButton: some View {
		Button {
			withAnimation {
				isExpanded.toggle()
			}
		} label: {
			HStack {
				Image(systemName: "chevron.down")
					.rotationEffect(.degrees(isExpanded ? 0 : -90))
				
				Text(title)
					.foregroundColor(.primary)
				
				Spacer()
			}
			.font(.title2.weight(.semibold))
		}
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
