import SwiftUI
import ValorantAPI
import HandyOperators

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
				<- LocalDataProvider.dataFetched
			gameInfo = info
			let userIDs = info.players.map(\.id)
			try await $0.fetchUsers(for: userIDs)
		}
		.navigationTitle("Live Match")
		.navigationBarTitleDisplayMode(.inline)
	}
}
