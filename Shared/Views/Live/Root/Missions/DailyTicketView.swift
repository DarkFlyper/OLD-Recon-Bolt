import SwiftUI
import Collections
import ValorantAPI

struct DailyTicketView: View {
	var milestones: [DailyTicketProgress.Milestone]
	
	var body: some View {
		HStack {
			ForEach(milestones.indexed(), id: \.index) { index, milestone in // evil
				marker(for: milestone)
				if index < milestones.count - 1 {
					Capsule()
						.frame(height: 1)
						.accentedOrFaded(shouldAccent: milestone.isComplete)
						.opacity(0.75)
				}
			}
		}
	}
	
	func marker(for milestone: DailyTicketProgress.Milestone) -> some View {
		ZStack {
			// target: size 32 when maxed
			let thickness = 10.0 / 3
			let spacing = 1.0
			ForEach(0..<4) { index in
				let size: CGFloat = 6 + 2 * (CGFloat(index) * (thickness + spacing))
				let isComplete = milestone.progress > index
				Group {
					if isComplete {
						Circle()
					} else {
						Circle().strokeBorder(lineWidth: thickness)
					}
				}
				.accentedOrFaded(shouldAccent: isComplete)
				.frame(width: size, height: size)
			}
			
			if milestone.isComplete {
				Image(systemName: "checkmark")
					.foregroundColor(.white)
			}
		}
	}
}

extension View {
	func accentedOrFaded(shouldAccent: Bool) -> some View {
		foregroundStyle(shouldAccent ? AnyShapeStyle(.accentColor) : .init(.tertiary))
	}
}
