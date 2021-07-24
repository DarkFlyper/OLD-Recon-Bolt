import SwiftUI
import ValorantAPI

struct MatchDetailsHero: View {
	let data: MatchViewData
	
	var body: some View {
		ZStack {
			let mapID = data.details.matchInfo.mapID
			MapImage.splash(mapID)
				.aspectRatio(contentMode: .fill)
				.frame(height: 150)
				.clipped()
				.overlay(MapImage.Label(mapID: mapID).padding(6))
			
			VStack {
				ScoreSummaryView(data: data)
					.font(.largeTitle.weight(.bold))
				
				Text(data.details.matchInfo.queueName)
					.fontWeight(.medium)
					.foregroundStyle(.secondary)
			}
			.padding()
			.background(Material.ultraThin)
			.cornerRadius(8)
			.shadow(radius: 10)
		}
	}
}

extension ScoreSummaryView {
	init(data: MatchViewData) {
		self.init(teams: data.details.teams, ownTeamID: data.myself?.teamID)
	}
}

#if DEBUG
struct MatchDetailsHero_Previews: PreviewProvider {
	static var previews: some View {
		MatchDetailsHero(data: PreviewData.singleMatchData)
			.previewLayout(.sizeThatFits)
			.inEachColorScheme()
	}
}
#endif
