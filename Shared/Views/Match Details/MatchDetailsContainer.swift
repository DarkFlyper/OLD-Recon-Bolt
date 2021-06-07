import SwiftUI
import ValorantAPI

struct MatchDetailsContainer: View {
	@EnvironmentObject private var loadManager: ValorantLoadManager
	
	let matchID: Match.ID
	let userID: User.ID
	
	@State var matchDetails: MatchDetails?
	
	var body: some View {
		Group {
			if let details = matchDetails {
				MatchDetailsView(matchDetails: details, userID: userID)
			} else {
				ProgressView()
			}
		}
		.loadErrorTitle("Could not load match details!")
		.onAppear {
			if matchDetails == nil {
				loadManager.load {
					$0.getMatchDetails(matchID: matchID)
				} onSuccess: { matchDetails = $0 }
			}
		}
		.navigationTitle("Match Details")
		.in {
			#if os(iOS)
			$0.navigationBarTitleDisplayMode(.inline)
			#endif
		}
	}
}
