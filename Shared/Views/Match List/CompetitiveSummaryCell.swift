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
			HStack(spacing: 16) {
				Spacer(minLength: 0)
				
				currentActInfo
					.fixedSize()
				
				let acts = assets?.seasons.actsInOrder
				let mostRecentActInfo = acts?
					.compactMap { act in summary.competitiveInfo?.bySeason?[act.id].map { (act, $0) } }
					.last { $0.1.winCount > 0 }
				if let (act, info) = mostRecentActInfo {
					Spacer(minLength: 0)
					
					actRankInfo(for: info, in: act)
				}
				
				Spacer(minLength: 0)
			}
			.frame(maxWidth: .infinity)
			.fixedSize(horizontal: false, vertical: true)
			.padding(.vertical)
		}
	}
	
	@ViewBuilder
	private var currentActInfo: some View {
		VStack {
			let act = assets?.seasons.currentAct()
			let info = act.flatMap { summary.competitiveInfo?.bySeason?[$0.id] }
			let tierInfo = assets?.seasons.tierInfo(number: info?.competitiveTier ?? 0, in: act)
			
			RankInfoView(summary: summary, lineWidth: 5, shouldFallBackOnPrevious: false)
				.frame(height: 96)
			
			if let tierInfo {
				Text(tierInfo.name)
					.font(primaryFont)
			}
			
			Text("\(info?.adjustedRankedRating ?? 0) RR")
				.font(secondaryFont)
			
			if let info, info.leaderboardRank > 0 {
				LeaderboardRankView(rank: info.leaderboardRank, tierInfo: tierInfo)
			}
		}
	}
	
	@ViewBuilder
	private func actRankInfo(for info: CareerSummary.SeasonInfo, in act: Act) -> some View {
		VStack {
			let tierInfo = assets?.seasons.tierInfo(number: info.competitiveTier, in: act)
			
			ActRankView(seasonInfo: info)
				.frame(width: 120, height: 120)
				.padding(.top, -10)
				.fixedSize()
				.overlay(
					CompetitiveTierImage(tierInfo: tierInfo)
						.frame(width: 40, height: 40)
						.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
						.shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
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
			.buttonStyle(.navigationLinkPreview)
			.previewLayout(.sizeThatFits)
		
		List {
			CompetitiveSummaryCell(summary: PreviewData.summary <- {
				$0.competitiveInfo!.bySeason = $0.competitiveInfo!.bySeason!
					.filter { $0.key == act.id }
			})
		}
		.withToolbar()
		.previewLayout(.fixed(width: 350, height: 400))
	}
}
#endif
