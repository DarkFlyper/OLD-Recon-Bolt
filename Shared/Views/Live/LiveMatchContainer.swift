import SwiftUI
import ValorantAPI

struct LiveMatchContainer: View {
	let matchID: Match.ID
	let userID: User.ID
	@State var gameInfo: LiveGameInfo?
	
	var body: some View {
		VStack {
			if let gameInfo = gameInfo {
				LiveMatchView(gameInfo: gameInfo, userID: userID)
			} else {
				ProgressView()
			}
		}
		.valorantLoadTask {
			let info = try await $0.getLiveGameInfo(matchID)
			LocalDataProvider.shared.dataFetched(info)
			gameInfo = info
			let userIDs = info.players.map(\.id)
			try await LocalDataProvider.shared.fetchUsers(for: userIDs, using: $0)
		}
		.navigationTitle("Live Match")
		.navigationBarTitleDisplayMode(.inline)
	}
}
