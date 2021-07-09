import SwiftUI
import ValorantAPI
import HandyOperators

struct CompetitiveSummaryCell: View {
	let summary: CompetitiveSummary
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		content
			.frame(maxWidth: .infinity)
			.padding()
	}
	
	@ViewBuilder
	private var content: some View {
		VStack {
			let info = summary.skillsByQueue[.competitive]?.bySeason?[.current]
				?? .init(seasonID: .current, actRank: 0, competitiveTier: 0, rankedRating: 0)
			
			let tierInfo = assets?.latestTierInfo(number: info.competitiveTier)
			
			RankInfoView(summary: summary, lineWidth: 6)
				.frame(width: 96, height: 96)
			
			if let tierInfo = tierInfo {
				Text(tierInfo.name)
					.font(.callout.weight(.semibold))
			}
			
			Text("\(info.rankedRating) RR")
				.font(.caption)
		}
	}
}

#if DEBUG
struct CompetitiveSummaryCell_Previews: PreviewProvider {
	static var previews: some View {
		CompetitiveSummaryCell(summary: PreviewData.summary)
			.padding()
			.inEachColorScheme()
			.previewLayout(.sizeThatFits)
	}
}
#endif
