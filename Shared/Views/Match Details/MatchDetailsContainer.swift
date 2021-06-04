import SwiftUI
import ValorantAPI

struct MatchDetailsContainer: View {
	@EnvironmentObject private var loadManager: ValorantLoadManager
	@Environment(\.playerID) private var playerID
	
	let matchID: Match.ID
	
	@State var matchDetails: MatchDetails?
	
	var body: some View {
		Group {
			if let details = matchDetails {
				MatchDetailsView(matchDetails: details, playerID: playerID)
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

extension EnvironmentValues {
	private enum PlayerIDKey: EnvironmentKey {
		static let defaultValue: Player.ID? = nil
	}
	
	var playerID: Player.ID? {
		get { self[PlayerIDKey.self] }
		set { self[PlayerIDKey.self] = newValue }
	}
}
