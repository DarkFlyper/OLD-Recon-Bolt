import SwiftUI

struct CompetitiveTierImage: View {
	@Environment(\.assets) private var assets
	
	var tier: Int
	var actID: Act.ID? = nil
	
	var body: some View {
		if
			let tierInfo = assets?.seasons.tierInfo(number: tier, in: actID),
			let image = tierInfo.icon?.imageIfLoaded
		{
			image
				.resizable()
				// the unranked icon is horribly off-center; let's fix that
				.scaleEffect(tier == 0 ? 1.31 : 1, anchor: .top)
				.scaledToFit()
		} else {
			Color.gray
		}
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
		.background(Color(.darkGray))
		.previewLayout(.sizeThatFits)
	}
}
#endif
