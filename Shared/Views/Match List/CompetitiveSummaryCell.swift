import SwiftUI
import ValorantAPI
import HandyOperators

struct CompetitiveSummaryCell: View {
	let summary: CareerSummary?
	
	@Environment(\.seasons) private var seasons
	@Environment(\.colorScheme) private var colorScheme
	
	private let artworkSize = 96.0
	private let primaryFont = Font.callout.weight(.semibold)
	private let secondaryFont = Font.caption
	
	var body: some View {
		TransparentNavigationLink {
			if let summary {
				CareerSummaryView(summary: summary)
			}
		} label: {
			HStack(alignment: .rankIcon, spacing: 16) {
				Spacer(minLength: 0)
				
				currentActInfo
					.fixedSize()
					.frame(maxWidth: .infinity)
				
				peakInfo
					.fixedSize()
					.frame(maxWidth: .infinity)
				
				Spacer(minLength: 0)
			}
			.frame(maxWidth: .infinity)
			.fixedSize(horizontal: false, vertical: true)
			.padding(.vertical)
			.aligningListRowSeparator()
			.updatingGameConfig()
		}
		.disabled(summary == nil)
	}
	
	@ViewBuilder
	private var currentActInfo: some View {
		VStack {
			let act = seasons?.currentAct()
			let info = summary?.competitiveInfo?.inSeason(act?.id)
			let tierInfo = seasons?.tierInfo(number: info?.competitiveTier, in: act)
			
			SeasonLabel(season: act?.id)
				.font(secondaryFont)
			
			RankInfoView(summary: summary, size: artworkSize, lineWidth: 5, shouldFallBackOnPrevious: false)
				.alignmentGuide(.rankIcon) { $0[VerticalAlignment.center] }
			
			Group {
				if let tierInfo {
					Text(tierInfo.name)
						.font(primaryFont)
				} else {
					Text("Unknown Rank", comment: "Match List: should never appear unless assets are missing/outdated")
						.foregroundStyle(.secondary)
						.font(primaryFont)
				}
				
				Text("\(info?.adjustedRankedRating ?? 0) RR")
					.font(secondaryFont)
			}
			.placeholder(if: summary == nil)
			
			if let info, info.leaderboardRank > 0 {
				LeaderboardRankView(rank: info.leaderboardRank, tierInfo: tierInfo)
			}
		}
	}
	
	@ViewBuilder
	private var peakInfo: some View {
		if
			let peakRank = summary?.peakRank(seasons: seasons),
			let info = seasons?.tierInfo(peakRank)
		{
			VStack {
				SeasonLabel(season: peakRank.season)
					.font(secondaryFont)
				
				PeakRankIcon(
					peakRank: peakRank, tierInfo: info,
					size: artworkSize,
					borderOpacity: colorScheme == .dark ? 0.4 : 1 // it's very light, so this helps maintain the same contrast
				)
				
				VStack {
					Text(info.name)
						.font(primaryFont)
					Text("Lifetime Peak")
						.font(secondaryFont)
				}
			}
		}
	}
	
	@ViewBuilder
	private func actRankInfo(for info: CareerSummary.SeasonInfo, in act: Act) -> some View {
		VStack {
			let tierInfo = seasons?.tierInfo(number: info.competitiveTier, in: act)
			
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
struct CompetitiveSummaryCell_Previews: PreviewProvider, PreviewProviderWithAssets {
	static func previews(assets: AssetCollection) -> some View {
		let act = assets.seasons.with(PreviewData.gameConfig).currentAct()!
		
		CompetitiveSummaryCell(summary: PreviewData.summary)
			.buttonStyle(.navigationLinkPreview)
			.previewLayout(.sizeThatFits)
			.environmentObject(ImageManager())
			.previewDisplayName("Single Cell")
		
		List {
			Section {
				CompetitiveSummaryCell(summary: nil)
				
				CompetitiveSummaryCell(summary: PreviewData.summary <- {
					$0.competitiveInfo!.bySeason = $0.competitiveInfo!.bySeason!
						.filter { $0.key == act.id }
				})
			}
			
			Section {
				CompetitiveSummaryCell(summary: PreviewData.summary)
			}
			
			Section {
				CompetitiveSummaryCell(summary: PreviewData.summary <- {
					$0.competitiveInfo!.bySeason![act.id] = .init(
						seasonID: act.id,
						leaderboardRank: 152,
						competitiveTier: 27,
						rankedRating: 543
					)
				})
			}
			
			Section {
				CompetitiveSummaryCell(summary: PreviewData.summary <- {
					$0.competitiveInfo!.bySeason![act.id] = .init(seasonID: act.id, competitiveTier: 20, rankedRating: 32)
				})
			}
		}
		.withToolbar()
		.environmentObject(ImageManager())
		.previewDisplayName("List")
	}
}
#endif
