import SwiftUI

struct LeaderboardRankView: View {
	var rank: Int
	var tierInfo: CompetitiveTier?
	
	var body: some View {
		ZStack {
			Capsule()
				.fill(tierInfo?.backgroundColor ?? .gray)
			
			let darkeningOpacity = 0.25
			
			Capsule()
				.fill(.black.opacity(darkeningOpacity))
				.blendMode(.plusDarker)
			
			Capsule()
				.fill(.white.opacity(darkeningOpacity))
				.blendMode(.plusLighter)
				.padding(1)
			
			Capsule()
				.fill(.black.opacity(darkeningOpacity))
				.blendMode(.plusDarker)
				.padding(3)
			
			let rankText = Text("Rank \(rank)")
				.font(.callout.weight(.semibold))
				.padding(.horizontal, 4)
				.padding(10)
			
			rankText
				.foregroundColor(.white.opacity(darkeningOpacity))
				.blendMode(.plusLighter)
			
			rankText
				.blendMode(.plusLighter)
		}
		.foregroundColor(.white)
		.fixedSize()
	}
}

#if DEBUG
struct LeaderboardRankView_Previews: PreviewProviderWithAssets {
	static func previews(assets: AssetCollection) -> some View {
		let act = assets.seasons.with(PreviewData.gameConfig).currentAct()!
		let ranks = assets.seasons.competitiveTiers[act.competitiveTiers]!
		let distinctlyColoredTiers = ranks.tiers.values
			.filter { $0.number % 3 == 0 }
			.sorted(on: \.number)
		
		VStack {
			LeaderboardRankView(rank: 69420)
			ForEach(distinctlyColoredTiers, id: \.number) { tier in
				LeaderboardRankView(rank: tier.number, tierInfo: tier)
			}
		}
		.padding()
		.previewLayout(.sizeThatFits)
	}
}
#endif
