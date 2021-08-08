import SwiftUI
import ValorantAPI
import HandyOperators

struct CompetitiveSummaryCell: View {
	let summary: CareerSummary
	
	@Environment(\.assets) private var assets
	
	private let artworkSize = 96.0
	private let primaryFont = Font.callout.weight(.semibold)
	private let secondaryFont = Font.caption
	
	var body: some View {
		NavigationLink {
			CareerSummaryView(summary: summary)
		} label: {
			HStack {
				currentActInfo
					.fixedSize() // TODO: remove once text no longer gets cut off without
				
				let acts = assets?.seasons.actsInOrder
				let mostRecentActInfo = acts?
					.compactMap { act in summary.competitiveInfo?.bySeason?[act.id].map { (act, $0) } }
					.last { $0.1.winCount > 0 }
				if let (act, info) = mostRecentActInfo {
					Spacer()
					
					actRankInfo(for: info, in: act)
				}
			}
			.frame(maxWidth: .infinity)
			.fixedSize(horizontal: false, vertical: true)
			.padding()
		}
	}
	
	@ViewBuilder
	private var currentActInfo: some View {
		VStack {
			let act = assets?.seasons.currentAct()
			let info = act.flatMap { summary.competitiveInfo?.bySeason?[$0.id] }
			let tierInfo = assets?.seasons.tierInfo(number: info?.competitiveTier ?? 0, in: act)
			
			RankInfoView(summary: summary, lineWidth: 6, shouldFallBackOnPrevious: false)
				.frame(height: artworkSize)
			
			if let tierInfo = tierInfo {
				Text(tierInfo.name)
					.font(primaryFont)
			}
			
			Text("\(info?.adjustedRankedRating ?? 0) RR")
				.font(secondaryFont)
		}
	}
	
	@ViewBuilder
	private func actRankInfo(for info: CareerSummary.SeasonInfo, in act: Act) -> some View {
		VStack {
			let tierInfo = assets?.seasons.tierInfo(number: info.competitiveTier, in: act)
			
			ActRankView(seasonInfo: info)
				.frame(height: artworkSize)
				.overlay(
					CompetitiveTierImage(tierInfo: tierInfo)
						.frame(width: 32, height: 32)
						.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
				)
			
			Text(act.name)
				.font(primaryFont)
			
			if let episode = act.episode {
				Text(episode.name)
					.font(secondaryFont)
			}
		}
	}
}

#if DEBUG
struct CompetitiveSummaryCell_Previews: PreviewProvider {
	static let assets = AssetManager.forPreviews.assets!
	static let act = assets.seasons.currentAct()!
	
	static var previews: some View {
		CompetitiveSummaryCell(summary: PreviewData.summary)
			.padding()
			.inEachColorScheme()
			.previewLayout(.sizeThatFits)
		
		CompetitiveSummaryCell(summary: PreviewData.summary <- {
			$0.competitiveInfo!.bySeason = $0.competitiveInfo!.bySeason!
				.filter { $0.key == act.id }
		})
			.padding()
			.previewLayout(.sizeThatFits)
	}
}
#endif
