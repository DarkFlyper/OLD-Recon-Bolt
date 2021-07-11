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
				let tierInfo = assets?.seasons.tierInfo(number: info?.competitiveTier ?? 0, in: info?.seasonID)
				
				if shouldShowProgress {
					ZStack {
						tierInfo?.backgroundColor
						Color.black.opacity(0.25).blendMode(.plusDarker)
					}
					.mask(Circle())
					.padding(-0.5 * thickerWidth)
					
					let stroke = StrokeStyle(lineWidth: lineWidth, lineCap: .round)
					let thickerStroke = StrokeStyle(lineWidth: thickerWidth, lineCap: .round)
					
					let ring = Circle().rotation(Angle(degrees: -90))
					let ratingArc = ring.trim(from: 0, to: CGFloat(info?.rankedRating ?? 0) / 100)
					
					ZStack {
						// background ring to fill in with rating arc
						ring
							.stroke(style: stroke)
							.foregroundColor(tierInfo?.backgroundColor)
						
						// knock out background ring around rating arc
						ratingArc
							.stroke(style: thickerStroke)
							.blendMode(.destinationOut)
					}
					.compositingGroup()
					
					ratingArc
						.stroke(style: stroke)
						.foregroundColor(.white)
						.opacity(0.5)
						.blendMode(.plusLighter)
				}
				
				let tier = info?.competitiveTier ?? 0
				
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
