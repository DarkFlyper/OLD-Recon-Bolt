import SwiftUI

struct AsyncButton<Label: View>: View {
	var role: ButtonRole? = nil
	var action: () async -> Void
	@ViewBuilder let label: () -> Label
	
	@MainActor
	@State private var isRunning = false
	
	var body: some View {
		Button(role: role) {
			isRunning = true
			async {
				await action()
				// TODO: figure out if this is necessary
				//await MainActor.run {
					isRunning = false
				//}
			}
		} label: {
			label()
				.opacity(isRunning ? 0.25 : 1)
				.overlay {
					if isRunning {
						ProgressView()
					}
				}
		}
		.disabled(isRunning)
	}
}

extension AsyncButton where Label == Text {
	init(
		_ titleKey: LocalizedStringKey,
		role: ButtonRole? = nil,
		action: @escaping () async -> Void
	) {
		self.init(role: role, action: action) { Text(titleKey) }
	}
}

#if DEBUG
struct AsyncButton_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			AsyncButton("Quick") { print("quick") }
			
			AsyncButton("Long") {
				print("long starting")
				await Task.sleep(seconds: 2, tolerance: 0.1)
				print("long done")
			}
		}
		.padding()
		.buttonStyle(.bordered)
		.previewLayout(.sizeThatFits)
	}
}
#endif
