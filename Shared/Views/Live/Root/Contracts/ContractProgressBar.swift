import SwiftUI

struct ContractProgressBar: View {
	var data: ContractData
	
	var body: some View {
		VStack(spacing: 4) {
			GeometryReader { geometry in
				let spacing = 1.0
				let xpScale = (geometry.size.width - spacing * CGFloat(data.levels.count - 1)) / CGFloat(data.totalXP)
				
				HStack(spacing: spacing) {
					let currentXP = data.contract.progression.totalEarned
					
					ForEach(data.levels) { level in
						ZStack(alignment: .leading) {
							let range = level.xpRange
							
							Color.gray.opacity(0.25)
							
							if range.contains(currentXP) {
								Color.accentColor.opacity(0.25)
							}
							
							let progressInLevel = currentXP.clamped(to: range.lowerBound...range.upperBound) - range.lowerBound
							Color.accentColor
								.frame(width: CGFloat(progressInLevel) * xpScale)
								.cornerRadius(0.5)
						}
						.frame(width: CGFloat(level.info.xp) * xpScale)
						.cornerRadius(0.5)
					}
				}
			}
			.frame(height: 4)
			.clipShape(Capsule())
			.compositingGroup()
			
			HStack {
				Text("Level \(data.contract.levelReached) / \(data.levels.count)")
				
				Spacer()
				
				if let nextLevel = data.nextLevel {
					let xpProgress = data.contract.progressionTowardsNextLevel
					let xpGoal = nextLevel.info.xp
					
					Text("\(xpProgress) / \(xpGoal) XP")
				}
			}
			.foregroundColor(.secondary)
			.font(.caption)
			.frame(maxWidth: .infinity, alignment: .trailing)
		}
	}
}
