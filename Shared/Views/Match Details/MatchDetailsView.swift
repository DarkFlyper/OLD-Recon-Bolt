import SwiftUI
import SwiftUIMissingPieces
import ValorantAPI
import VisualEffects
import HandyOperators

struct MatchDetailsView: View {
	let matchDetails: MatchDetails
	@State var myself: Player?
	
	init(matchDetails: MatchDetails, playerID: Player.ID?) {
		self.matchDetails = matchDetails
		
		let candidates = matchDetails.players.filter { $0.id == playerID }
		assert(candidates.count <= 1)
		_myself = .init(wrappedValue: candidates.first)
	}
	
	var body: some View {
		ScrollView {
			VStack(spacing: 0) {
				MatchDetailsHero(matchDetails: matchDetails, myself: myself)
					.edgesIgnoringSafeArea(.horizontal)
				
				Group {
					ScoreboardView(players: matchDetails.players, myself: $myself)
					
					Divider().padding(.horizontal)
					
					if KillBreakdownView.canDisplay(for: matchDetails) {
						KillBreakdownView(matchDetails: matchDetails, myself: myself)
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
