import SwiftUI
import ValorantAPI

struct LiveMatchContainer: View {
	@EnvironmentObject private var loadManager: ValorantLoadManager
	
	let matchID: Match.ID
	let user: User
	@State var gameInfo: LiveGameInfo?
	@State var users: [User.ID: User]?
	
	var body: some View {
		VStack {
			if let gameInfo = gameInfo, let users = users {
				LiveMatchView(gameInfo: gameInfo, user: user, users: users)
			} else {
				ProgressView()
			}
		}
		.task {
			await loadManager.load {
				let info = try await $0.getLiveGameInfo(matchID)
				gameInfo = info
				let userIDs = info.players.map(\.id)
				users = .init(values: try await $0.getUsers(for: userIDs))
			}
		}
		.navigationTitle("Live Match")
		.navigationBarTitleDisplayMode(.inline)
	}
}

struct LiveMatchView: View {
	private typealias PlayerInfo = LiveGameInfo.PlayerInfo
	
	@EnvironmentObject private var assetManager: AssetManager
	
	let gameInfo: LiveGameInfo
	let user: User
	let users: [User.ID: User]
	
	let ownPlayer: LiveGameInfo.PlayerInfo
	
	init(gameInfo: LiveGameInfo, user: User, users: [User.ID: User]) {
		self.gameInfo = gameInfo
		self.user = user
		self.users = users
		
		ownPlayer = gameInfo.players.first { $0.id == user.id }!
	}
	
	var body: some View {
		ScrollView {
			VStack(spacing: 0) {
				hero
				
				playerList
			}
		}
	}
	
	@ViewBuilder
	private var hero: some View {
		ZStack {
			MapImage.splash(gameInfo.mapID)
				.aspectRatio(contentMode: .fill)
				.frame(height: 200)
				.clipped()
				.overlay(MapImage.Label(mapID: gameInfo.mapID).padding(6))
			
			VStack(spacing: 10) {
				if let queueID = gameInfo.matchmakingData.queueID {
					Text(queueID.name)
						.fontWeight(.medium)
						.foregroundStyle(.secondary)
				}
			}
			.padding()
			.background(Material.thin)
			.cornerRadius(8)
			.shadow(radius: 10)
		}
	}
	
	@ViewBuilder
	private var playerList: some View {
		let teams = Dictionary(grouping: gameInfo.players, by: \.teamID)
		let allyTeam = teams[ownPlayer.teamID]!
		let enemyTeams = teams
			.filter { $0.key != ownPlayer.teamID }
			.sorted(on: \.key.rawValue)
		
		VStack(spacing: 10) {
			ForEach(allyTeam, content: playerView(for:))
			
			ForEach(enemyTeams, id: \.key) { teamID, team in
				Divider()
					.padding(.vertical, 5)
				
				ForEach(team, content: playerView(for:))
			}
		}
		.padding()
	}
	
	@ViewBuilder
	private func playerView(for player: PlayerInfo) -> some View {
		let isAlly = player.teamID == ownPlayer.teamID
		let relativeColor = player.id == user.id
			? Color.valorantSelf
			: isAlly ? .valorantBlue : .valorantRed
		let playerUser = users[player.id]!
		let iconSize: CGFloat = 48
		
		HStack {
			AgentImage.displayIcon(player.agentID)
				.dynamicallyStroked(radius: 1.5, color: .white)
				.frame(width: iconSize, height: iconSize)
				.mask(Circle())
				.background(Circle().fill(relativeColor).opacity(0.5).padding(2))
				.padding(2)
				.overlay(
					Circle()
						.strokeBorder(relativeColor, lineWidth: 2)
				)
			
			VStack(alignment: .leading, spacing: 4) {
				if !player.identity.isIncognito {
					HStack {
						Text(playerUser.gameName)
						Text("#\(playerUser.tagLine)")
							.foregroundColor(.secondary)
					}
				}
				
				let agentName = assetManager.assets?.agents[player.agentID]?.displayName
				Text(agentName ?? "Unknown Agent!")
					.fontWeight(.semibold)
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			
			if player.id != user.id {
				NavigationLink(destination: UserView(for: playerUser)) {
					Image(systemName: "person.crop.circle.fill")
						.padding(.horizontal, 4)
				}
			}
		}
		.accentColor(relativeColor)
	}
}

struct LiveMatchView_Previews: PreviewProvider {
	static var previews: some View {
		LiveMatchContainer(
			matchID: PreviewData.liveGameInfo.id,
			user: PreviewData.user,
			gameInfo: PreviewData.liveGameInfo,
			users: PreviewData.liveGameUsers
		)
		.withToolbar()
		.withMockValorantLoadManager()
		.withPreviewAssets()
	}
}
