import SwiftUI
import ValorantAPI

struct MatchDetailsContainer: View {
	let matchID: Match.ID
	let userID: User.ID
	
	@LocalData var details: MatchDetails?
	
	init(matchID: Match.ID, userID: User.ID) {
		self.matchID = matchID
		self.userID = userID
		self._details = .init(id: matchID)
	}
	
	var body: some View {
		Group {
			if let details {
				MatchDetailsView(data: .init(details: details, userID: userID))
			} else {
				ProgressView()
			}
		}
		.withLocalData($details, id: matchID, shouldAutoUpdate: true, shouldReportErrors: true)
		.navigationTitle(Text("Match Details", comment: "Match Details: title"))
		.navigationBarTitleDisplayMode(.inline)
	}
}
