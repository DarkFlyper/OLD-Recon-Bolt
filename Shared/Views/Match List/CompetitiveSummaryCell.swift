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
			let act = assets?.seasons.currentAct()
			let info = act.flatMap { summary.competitiveInfo?.bySeason?[$0.id] }
			let tierInfo = assets?.seasons.tierInfo(number: info?.competitiveTier ?? 0, in: act)
			
			RankInfoView(summary: summary, lineWidth: 6)
				.frame(width: 96, height: 96)
			
			if let tierInfo = tierInfo {
				Text(tierInfo.name)
					.font(.callout.weight(.semibold))
			}
			
			Text("\(info?.rankedRating ?? 0) RR")
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
