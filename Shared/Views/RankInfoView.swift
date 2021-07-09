import SwiftUI
import ValorantAPI
import HandyOperators

// FIXME: remove this. need to handle season assets
extension Season.ID {
	static let current = Self("2a27e5d2-4d30-c9e2-b15a-93b8909a442c")!
}

struct RankInfoView: View {
	let summary: CompetitiveSummary?
	var lineWidth: CGFloat = 4.0
	var shouldShowProgress = true
	var shouldFadeUnranked = false
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		let thickerWidth = lineWidth * 1.5
		let backgroundCircle = Circle().padding(-0.5 * thickerWidth)
		
		ZStack {
			if let summary = summary {
				let competitiveInfo = summary.skillsByQueue[.competitive]
				let info = competitiveInfo?.bySeason?[.current]
					?? .init(seasonID: .current, actRank: 0, competitiveTier: 0, rankedRating: 0)
				let tierInfo = assets?.latestTierInfo(number: info.competitiveTier)
				
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
					let ratingArc = ring.trim(from: 0, to: CGFloat(info.rankedRating) / 100)
					
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
						.opacity(0.6)
						.blendMode(.plusLighter)
				}
				
				CompetitiveTierImage(tier: info.competitiveTier)
					.scaleEffect(shouldShowProgress ? 0.75 : 1)
					.opacity(shouldFadeUnranked && info.competitiveTier == 0 ? 0.5 : 1)
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
	private static func summaryForTier(_ tier: Int) -> CompetitiveSummary {
		PreviewData.summary <- {
			$0
				.skillsByQueue[.competitive]!
				.bySeason![.current]!
				.competitiveTier = tier
		}
	}
	
	static var previews: some View {
		Group {
			RankInfoView(summary: PreviewData.summary <- { $0.skillsByQueue = [:] })
				.frame(height: 64)
			RankInfoView(summary: summaryForTier(0))
				.frame(height: 64)
			RankInfoView(summary: summaryForTier(8), shouldShowProgress: false)
				.frame(width: 64, height: 64)
				.preferredColorScheme(.dark)
			RankInfoView(summary: PreviewData.summary, lineWidth: 8)
				.frame(width: 128, height: 128)
			
			LazyHGrid(rows: [.init(), .init(), .init()], spacing: 20) {
				ForEach(0..<25) { tier in
					RankInfoView(summary: summaryForTier(tier))
						.frame(width: 64)
				}
			}
			.padding()
			.frame(height: 250)
			.inEachColorScheme()
		}
		.previewLayout(.sizeThatFits)
	}
}
#endif
