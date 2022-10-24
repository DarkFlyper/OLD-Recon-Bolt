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
		}
	}
	
	@ViewBuilder
	private var currentActInfo: some View {
		VStack {
			let act = assets?.seasons.currentAct()
			let info = act.flatMap { summary.competitiveInfo?.bySeason?[$0.id] }
			let tierInfo = assets?.seasons.tierInfo(number: info?.competitiveTier ?? 0, in: act)
			
			seasonLabel(for: act?.id)
			
			RankInfoView(summary: summary, size: artworkSize, lineWidth: 5, shouldFallBackOnPrevious: false)
				.alignmentGuide(.rankIcon) { $0[VerticalAlignment.center] }
			
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
	private var peakInfo: some View {
		if let peakRank = summary.peakRank(), let info = assets?.seasons.tierInfo(peakRank) {
			VStack {
				seasonLabel(for: peakRank.season)
				
				info.rankTriangleUpwards?.view(shouldLoadImmediately: true)
					.scaleEffect(0.85) // looks too large otherwise
					.shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 4)
					.alignmentGuide(.rankIcon) { $0[VerticalAlignment.center] }
					.frame(width: artworkSize, height: artworkSize)
				
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
	func seasonLabel(for season: Act.ID?) -> some View {
		if let season, let act = assets?.seasons.acts[season] {
			HStack {
				if let episode = act.episode {
					Text(episode.name.replacingOccurrences(of: "EPISODE", with: "EP"))
						.fontWeight(.medium)
					Text("//")
						.foregroundStyle(.tertiary)
				}
				Text(act.name)
			}
			.foregroundStyle(.secondary)
			.font(secondaryFont)
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

private extension VerticalAlignment {
	static let rankIcon = Self(NewID.self)
	
	private enum NewID: AlignmentID {
		static func defaultValue(in context: ViewDimensions) -> CGFloat {
			context.height / 2
		}
	}
}

#if DEBUG
struct CompetitiveSummaryCell_Previews: PreviewProvider, PreviewProviderWithAssets {
	static func previews(assets: AssetCollection) -> some View {
		let act = assets.seasons.currentAct()!
		
		CompetitiveSummaryCell(summary: PreviewData.summary)
			.buttonStyle(.navigationLinkPreview)
			.previewLayout(.sizeThatFits)
			.environmentObject(ImageManager())
		
		List {
			Section {
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
	}
}
#endif
