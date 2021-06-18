import SwiftUI
import ValorantAPI

struct MatchDetailsContainer: View {
	let matchID: Match.ID
	let userID: User.ID
	
	@State var matchDetails: MatchDetails?
	
	@Environment(\.valorantLoad) private var load
	
	var body: some View {
		Group {
			if let details = matchDetails {
				MatchDetailsView(matchDetails: details, userID: userID)
			} else {
				ProgressView()
			}
		}
		.loadErrorAlertTitle("Could not load match details!")
		// TODO: is this being applied to a group making it be called multiple times?
		.task {
			guard matchDetails == nil else { return }
			
			await load {
				matchDetails = try await $0.getMatchDetails(matchID: matchID)
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
