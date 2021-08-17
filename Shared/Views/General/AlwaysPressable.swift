import SwiftUI

extension View {
	/// Allows you to track whether any view, even a button, is being pressed, even when it's disabled.
	func alwaysPressable(isPressing: GestureState<Bool>) -> some View {
		modifier(AlwaysHoldable(isPressing: isPressing))
	}
}

private struct AlwaysHoldable: ViewModifier {
	@GestureState var isPressing: Bool
	
	@Environment(\.isEnabled) private var isEnabled
	
	init(isPressing: GestureState<Bool>) {
		_isPressing = isPressing
	}
	
	func body(content: Content) -> some View {
		ZStack {
			content
			
			Color.clear
				.contentShape(Rectangle()) // clear color has empty shape by default
				.allowsHitTesting(!isEnabled) // only when the content couldn't work anyway
				.layoutPriority(-1)
		}
		.environment(\.isEnabled, isEnabled) // reset modified isEnabled
		.gesture(
			DragGesture(minimumDistance: 0)
				.updating($isPressing) { _, isHolding, _ in
					isHolding = true
				}
		)
		.environment(\.isEnabled, true) // enable the gesture
	}
}
