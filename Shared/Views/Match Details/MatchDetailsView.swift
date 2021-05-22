import SwiftUI
import SwiftUIMissingPieces
import ValorantAPI
import VisualEffects
import HandyOperators

struct MatchDetailsView: View {
	let matchDetails: MatchDetails
	let myself: Player?
	
	init(matchDetails: MatchDetails, playerID: Player.ID?) {
		self.matchDetails = matchDetails
		
		let candidates = matchDetails.players.filter { $0.id == playerID }
		assert(candidates.count <= 1)
		myself = candidates.first
	}
	
	var body: some View {
		ScrollView {
			VStack(spacing: 0) {
				MatchDetailsHero(matchDetails: matchDetails, myself: myself)
					.edgesIgnoringSafeArea(.horizontal)
				
				ScoreboardView(players: matchDetails.players, myself: myself)
			}
		}
	}
}

struct MatchDetailsView_Previews: PreviewProvider {
	static var previews: some View {
		ForEach(ColorScheme.allCases, id: \.self) { scheme in
			MatchDetailsView(
				matchDetails: PreviewData.singleMatch,
				playerID: PreviewData.playerID
			)
			.preferredColorScheme(scheme)
		}
		.navigationTitle("Match Details")
		.withToolbar(allowLargeTitles: false)
		.environmentObject(AssetManager.forPreviews)
	}
}
