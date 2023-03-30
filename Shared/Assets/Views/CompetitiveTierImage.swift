import SwiftUI

struct CompetitiveTierImage: View {
	@EnvironmentObject private var imageManager: ImageManager
	@Environment(\.seasons) private var seasons
	
	var tier: Int
	var tierInfo: CompetitiveTier?
	var act: Act?
	var actID: Act.ID?
	var time: Date?
	
	var body: some View {
		if
			let tierInfo = tierInfo
				?? seasons?.tierInfo(number: tier, in: act)
				?? seasons?.tierInfo(number: tier, in: actID)
				?? seasons?.currentTierInfo(number: tier, at: time),
			let icon = tierInfo.icon
		{
			icon.view(shouldLoadImmediately: true)
				// the unranked icon is horribly off-center; let's fix that
				.scaleEffect(tier == 0 ? 1.31 : 1, anchor: .top)
				.scaledToFit()
		} else {
			Circle().opacity(0.1)
				.aspectRatio(1, contentMode: .fit)
		}
	}
}

extension CompetitiveTierImage {
	init(tierInfo: CompetitiveTier?) {
		self.tier = tierInfo?.number ?? 0
		self.tierInfo = tierInfo
	}
}

#if DEBUG
struct CompetitiveTierImage_Previews: PreviewProvider {
	static var previews: some View {
		VStack {
			CompetitiveTierImage(tier: 0)
			CompetitiveTierImage(tier: 14)
			CompetitiveTierImage(tier: 22)
			CompetitiveTierImage(tier: 24)
			CompetitiveTierImage(tier: 42)
		}
		.fixedSize()
		.padding()
		.environmentObject(ImageManager())
		.background(Color(.darkGray))
		.previewLayout(.sizeThatFits)
	}
}
#endif
