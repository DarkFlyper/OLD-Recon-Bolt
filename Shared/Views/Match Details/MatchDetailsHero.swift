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
				
				data.details.matchInfo.queueLabel
					.font(.body.weight(.medium))
					.foregroundStyle(.secondary)
			}
			.padding()
			.background(Material.ultraThin)
			.cornerRadius(8)
			.shadow(radius: 10)
			.contextMenu {
				Button {
					UIPasteboard.general.string = data.details.id.description
				} label: {
					Label("Copy Match ID", systemImage: "square.on.square")
				}
			}
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
	}
}
#endif
