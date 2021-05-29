import SwiftUI
import ValorantAPI

struct MatchDetailsView: View {
	let data: MatchViewData
	@State var highlight = PlayerHighlightInfo()
	
	init(matchDetails: MatchDetails, playerID: Player.ID?) {
		data = .init(details: matchDetails, playerID: playerID)
	}
	
	var body: some View {
		ScrollView {
			VStack(spacing: 0) {
				MatchDetailsHero(data: data)
					.edgesIgnoringSafeArea(.horizontal)
				
				Group {
					ScoreboardView(data: data, highlight: $highlight)
					
					Divider().padding(.horizontal)
					
					if KillBreakdownView.canDisplay(for: data) {
						KillBreakdownView(data: data, highlight: $highlight)
					}
				}
				.padding(.top)
			}
		}
	}
}

#if DEBUG
struct MatchDetailsView_Previews: PreviewProvider {
	static var previews: some View {
		MatchDetailsView(
			matchDetails: PreviewData.singleMatch,
			playerID: PreviewData.playerID
		)
		.navigationTitle("Match Details")
		.withToolbar(allowLargeTitles: false)
		.inEachColorScheme()
		.environmentObject(AssetManager.forPreviews)
	}
}
#endif
