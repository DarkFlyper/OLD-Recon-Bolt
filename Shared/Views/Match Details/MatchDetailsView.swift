import SwiftUI
import ValorantAPI

struct MatchDetailsView: View {
	@State var data: MatchViewData
	
	init(matchDetails: MatchDetails, playerID: Player.ID?) {
		_data = .init(wrappedValue: .init(details: matchDetails, playerID: playerID))
	}
	
	var body: some View {
		ScrollView {
			VStack(spacing: 0) {
				MatchDetailsHero(data: data)
					.edgesIgnoringSafeArea(.horizontal)
				
				Group {
					ScoreboardView(data: $data)
					
					Divider().padding(.horizontal)
					
					if KillBreakdownView.canDisplay(for: data) {
						KillBreakdownView(data: $data)
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
