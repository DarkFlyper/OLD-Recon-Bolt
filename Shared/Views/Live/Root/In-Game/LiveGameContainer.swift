import SwiftUI
import ValorantAPI
import HandyOperators

struct LiveGameContainer: View {
	var userID: User.ID
	var playersInParty: Set<Player.ID>
	@State var activeMatch: ActiveMatch?
	@State var details: Details?
	
	@State private var hasEnded = false
	
	@Environment(\.valorantLoad) private var load
	@Environment(\.scenePhase) private var scenePhase
	@Environment(\.dismiss) private var dismiss
	
	var body: some View {
		content
			.onSceneActivation(perform: refreshActiveMatch)
			.valorantLoadTask(id: details?.playerIDs) {
				guard let playerIDs = details?.playerIDs else { return }
				try await $0.fetchUsers(for: playerIDs)
			}
			.task {
				while !Task.isCancelled {
					await refreshActiveMatch()
					await Task.sleep(seconds: 5, tolerance: 1)
				}
			}
			.task(id: activeMatch) {
				await fetchDetails()
			}
			.task(id: hasEnded) {
				if hasEnded { dismiss() }
			}
	}
	
	@ViewBuilder
	var content: some View {
		switch details {
		case .pregame(let pregameInfo, let inventory)?:
			AgentSelectView(
				userID: userID,
				inventory: inventory,
				pregameInfo: pregameInfo
			)
			.id(pregameInfo.id)
			.anonymizing(additionally: .some(playersToAnonymize(from: pregameInfo.team.players.lazy.map(\.identity))))
		case .liveGame(let liveGameInfo)?:
			LiveMatchView(gameInfo: liveGameInfo, userID: userID)
				.anonymizing(additionally: .some(playersToAnonymize(from: liveGameInfo.players.lazy.map(\.identity))))
		case nil:
			ProgressView()
		}
	}
	
	func playersToAnonymize(from players: some Collection<Player.Identity>) -> Set<Player.ID> {
		Set(players.lazy.filter { !playersInParty.contains($0.id) && $0.isIncognito }.map(\.id))
	}
	
	func fetchDetails() async {
		await load {
			guard let activeMatch else { return }
			if activeMatch.inPregame {
				async let inventory = $0.getInventory()
				details = .pregame(
					try await $0.getLivePregameInfo(activeMatch.id)
					<- LocalDataProvider.dataFetched,
					try await inventory
				)
			} else {
				details = .liveGame(
					try await $0.getLiveGameInfo(activeMatch.id)
					<- LocalDataProvider.dataFetched
				)
			}
		}
	}
	
	func refreshActiveMatch() async {
		await load {
			if let newMatch = try await $0.getActiveMatch() {
				hasEnded = false
				activeMatch = newMatch
			} else {
				hasEnded = true
				activeMatch = nil
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
			playersInParty: [],
			activeMatch: .init(id: PreviewData.liveGameInfo.id, inPregame: false),
			details: .liveGame(PreviewData.liveGameInfo)
		)
		.withToolbar()
	}
}
#endif
