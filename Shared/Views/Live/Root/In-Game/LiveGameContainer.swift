import SwiftUI
import ValorantAPI
import HandyOperators

struct LiveGameContainer: View {
	var userID: User.ID
	@State var activeMatch: ActiveMatch
	@State var details: Details?
	
	@State private var isShowingEndedAlert = false
	@State private var refreshInterval: TimeInterval = 1
	
	@Environment(\.valorantLoad) private var load
	@Environment(\.scenePhase) private var scenePhase
	@Environment(\.dismiss) private var dismiss
	
	var body: some View {
		content
			.onSceneActivation(perform: refresh)
			.valorantLoadTask(id: details?.playerIDs) {
				guard let playerIDs = details?.playerIDs else { return }
				try await $0.fetchUsers(for: playerIDs)
			}
			.task {
				while !Task.isCancelled {
					await refresh()
					await Task.sleep(seconds: refreshInterval, tolerance: 0.1 * refreshInterval)
				}
			}
			.alert(
				"Game Ended!",
				isPresented: $isShowingEndedAlert
			) {
				Button("Exit") { dismiss() }
			}
	}
	
	@ViewBuilder
	var content: some View {
		switch details {
		case .pregame(let pregameInfo, let inventory)?:
			AgentSelectView(
				pregameInfo: Binding(
					get: { pregameInfo },
					set: { details = .pregame($0, inventory) }
				),
				userID: userID,
				inventory: inventory
			)
		case .liveGame(let liveGameInfo)?:
			LiveMatchView(gameInfo: liveGameInfo, userID: userID)
				.toolbar {
					AsyncButton(action: refresh) {
						Label("Refresh", systemImage: "arrow.clockwise")
					}
				}
		case nil:
			ProgressView()
		}
	}
	
	func refresh() async {
		await load {
			do {
				if activeMatch.inPregame {
					async let inventory = $0.getInventory(for: userID)
					details = .pregame(
						try await $0.getLivePregameInfo(activeMatch.id)
						<- LocalDataProvider.dataFetched,
						try await inventory
					)
					refreshInterval = 1
				} else {
					details = .liveGame(
						try await $0.getLiveGameInfo(activeMatch.id)
						<- LocalDataProvider.dataFetched
					)
					refreshInterval = 5
				}
			} catch ValorantClient.APIError.badResponseCode(404, _, _) {
				refreshInterval = 5
				if let newMatch = try await $0.getActiveMatch() {
					activeMatch = newMatch
					await refresh()
				}
			}
		}
	}
	
	enum Details {
		case pregame(LivePregameInfo, Inventory)
		case liveGame(LiveGameInfo)
		
		var playerIDs: [Player.ID] {
			switch self {
			case .pregame(let livePregameInfo, _):
				return livePregameInfo.team.players.map(\.id)
			case .liveGame(let liveGameInfo):
				return liveGameInfo.players.map(\.id)
			}
		}
	}
}

#if DEBUG
struct LiveGameContainer_Previews: PreviewProvider {
	static var previews: some View {
		LiveGameContainer(
			userID: PreviewData.userID,
			activeMatch: .init(id: PreviewData.liveGameInfo.id, inPregame: false),
			details: .liveGame(PreviewData.liveGameInfo)
		)
		.withToolbar()
	}
}
#endif
