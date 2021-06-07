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
					
					if KillBreakdownView.canDisplay(for: data) {
						Divider().padding(.horizontal)
						
						KillBreakdownView(data: data, highlight: $highlight)
					}
				}
				.padding(.top)
			}
			.padding(.bottom)
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
