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
		// TODO: is this being applied to a group making it be called multiple times?
		.task {
			guard matchDetails == nil else { return }
			
			await loadManager.load {
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
