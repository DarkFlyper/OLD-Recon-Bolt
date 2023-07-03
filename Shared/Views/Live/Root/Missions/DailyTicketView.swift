import SwiftUI
import Collections
import ValorantAPI
import HandyOperators

struct DailyTicketView: View {
	var milestones: [DailyTicketProgress.Milestone]
	
	var body: some View {
		HStack {
			ForEach(milestones.indexed(), id: \.index) { index, milestone in // evil
				marker(for: milestone)
				if index < milestones.count - 1 {
					Capsule()
						.frame(height: 1)
						.foregroundStyle(milestone.isComplete ? .accented : .faded)
						.opacity(0.75)
				}
			}
		}
	}
	
	func marker(for milestone: DailyTicketProgress.Milestone) -> some View {
		let maxSize = 32.0
		let layerThickness = maxSize / 4 / 2
		func size(for index: Int) -> CGFloat {
			2 * CGFloat(index) * layerThickness
		}
		
		return ZStack {
			let slot = Circle()
				.strokeBorder(.faded, lineWidth: layerThickness)
			slot.frame(size: size(for: 2))
			slot.frame(size: size(for: 4))
			
			if milestone.progress > 0 {
				Circle()
					.frame(size: size(for: milestone.progress))
					.foregroundStyle(.accentColor)
			}
			
			if milestone.isComplete {
				Image(systemName: "checkmark")
					.foregroundColor(.white)
			}
		}
	}
}

struct DailyTicketView_Previews: PreviewProvider {
	static func milestone(progress: Int) -> DailyTicketProgress.Milestone {
		.zero <- { $0.progress = progress }
	}
	
	static var previews: some View {
		VStack(spacing: 20) {
			DailyTicketView(milestones: [4, 3, 2, 1].map(milestone(progress:)))
			DailyTicketView(milestones: [4, 1, 0, 0].map(milestone(progress:)))
		}
		.padding()
		.foregroundStyle(.primary, .secondary, Color.primary.opacity(0.1))
	}
}
