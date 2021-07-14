import SwiftUI
import ValorantAPI

struct MatchDetailsContainer: View {
	let matchID: Match.ID
	let userID: User.ID
	
	@State private var details: MatchDetails?
	
	var body: some View {
		Group {
			if let details = details {
				MatchDetailsView(matchDetails: details, userID: userID)
			} else {
				ProgressView()
			}
		}
		.withLocalData($details, id: matchID, shouldAutoUpdate: true)
		.loadErrorAlertTitle("Could not load match details!")
		.navigationTitle("Match Details")
		#if os(iOS)
		.navigationBarTitleDisplayMode(.inline)
		#endif
	}
}
