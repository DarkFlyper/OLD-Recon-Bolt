import SwiftUI
import ValorantAPI
import HandyOperators

struct RankInfoView: View {
	let summary: CompetitiveSummary?
	var lineWidth = 4.0
	var shouldShowProgress = true
	var shouldFadeUnranked = false
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		let thickerWidth = lineWidth * 1.5
		let backgroundCircle = Circle().padding(-0.5 * thickerWidth)
		
		ZStack {
			if let summary = summary {
				let act = assets?.seasons.currentAct()
				let info = act.flatMap { summary.competitiveInfo?.bySeason?[$0.id] }
				let tier = info?.competitiveTier ?? 0
				let tierInfo = assets?.seasons.tierInfo(number: tier, in: info?.seasonID)
				
				if shouldShowProgress {
					let darkening = 0.25
					
					CircularProgressView(
						lineWidth: lineWidth,
						background: {
							ZStack {
								tierInfo?.backgroundColor
								Color.black.opacity(darkening).blendMode(.plusDarker)
							}
						},
						base: { Color.white.opacity(darkening).blendMode(.plusLighter) },
						layers: {
							CircularProgressLayer(
								end: CGFloat(info?.rankedRating ?? 0) / 100,
								shouldKnockOutSurroundings: true,
								color: .white, opacity: 0.5, blendMode: .plusLighter
							)
						}
					)
				}
				
				CompetitiveTierImage(tier: tier)
					.scaleEffect(shouldShowProgress ? 0.75 : 1)
					.opacity(shouldFadeUnranked && tier == 0 ? 0.5 : 1)
			} else {
				backgroundCircle.foregroundColor(.black.opacity(0.1))
			}
		}
		.aspectRatio(1, contentMode: .fit)
		.padding(lineWidth)
	}
}

#if DEBUG
struct RankInfoView_Previews: PreviewProvider {
	static let assets = AssetManager.forPreviews.assets!
	static let act = assets.seasons.currentAct()!
	static let ranks = assets.seasons.competitiveTiers[act.competitiveTiers]!
	
	private static func summary(forTier tier: Int) -> CompetitiveSummary {
		PreviewData.summary <- {
			$0.competitiveInfo!.bySeason![act.id]!.competitiveTier = tier
		}
	}
	
	static var previews: some View {
		Group {
			RankInfoView(summary: PreviewData.summary <- { $0.skillsByQueue = [:] })
				.frame(height: 64)
			RankInfoView(summary: summary(forTier: 0))
				.frame(height: 64)
				.inEachColorScheme()
			RankInfoView(summary: PreviewData.summary, shouldShowProgress: false)
				.frame(width: 64, height: 64)
			RankInfoView(summary: PreviewData.summary, lineWidth: 8)
				.frame(width: 128, height: 128)
			
			LazyHGrid(rows: [.init(), .init(), .init()], spacing: 20) {
				ForEach(ranks.tiers.indices) {
					RankInfoView(summary: summary(forTier: $0))
				}
				.frame(width: 64)
			}
			.padding()
			.frame(height: 250)
			.inEachColorScheme()
		}
		.previewLayout(.sizeThatFits)
	}
}
#endif
