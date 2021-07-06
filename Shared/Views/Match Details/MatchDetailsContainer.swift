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
		.withLocalData($details) { $0.matchDetails(for: matchID) }
		.loadErrorAlertTitle("Could not load match details!")
		.valorantLoadTask {
			try await LocalDataProvider.shared
				.fetchMatchDetails(for: matchID, using: $0)
		}
		.navigationTitle("Match Details")
		#if os(iOS)
		.navigationBarTitleDisplayMode(.inline)
		#endif
	}
}
