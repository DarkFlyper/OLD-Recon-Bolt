import SwiftUI
import ValorantAPI

struct MatchDetailsContainer: View {
	let matchID: Match.ID
	let userID: User.ID
	
	@LocalData private var details: MatchDetails?
	
	var body: some View {
		Group {
			if let details {
				MatchDetailsView(data: .init(details: details, userID: userID))
			} else {
				ProgressView()
			}
		}
		.withLocalData($details, id: matchID, shouldAutoUpdate: true, shouldReportErrors: true)
		.navigationTitle("Match Details")
		.navigationBarTitleDisplayMode(.inline)
	}
}
