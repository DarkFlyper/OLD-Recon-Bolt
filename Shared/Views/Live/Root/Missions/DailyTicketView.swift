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
						.foregroundColor(milestone.wasRedeemed ? .accentColor : .primary.opacity(0.2))
						.opacity(0.75)
				}
			}
		}
	}
	
	func marker(for milestone: DailyTicketProgress.Milestone) -> some View {
		ZStack {
			let thickness = 3.0
			let spacing = 1.0
			ForEach(0..<4) { index in
				let size: CGFloat = 5 + 2 * (CGFloat(index) * (thickness + spacing))
				let isComplete = milestone.progress > index
				Circle()
					.strokeBorder(lineWidth: thickness + (isComplete ? spacing : 0))
					.frame(width: size, height: size)
					.foregroundColor(isComplete ? .accentColor : .primary.opacity(0.2))
			}
			
			if milestone.wasRedeemed {
				Image(systemName: "checkmark")
					.foregroundColor(.white)
			}
		}
	}
}
