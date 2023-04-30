import SwiftUI
import ValorantAPI

@MainActor
struct LiveMatchView: View {
	let gameInfo: LiveGameInfo
	let userID: User.ID
	
	var body: some View {
		ScrollView {
			VStack(spacing: 0) {
				hero
				
				playerList
			}
		}
		.navigationTitle("Live Match")
		.navigationBarTitleDisplayMode(.inline)
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
				gameInfo.queueLabel
					.font(.body.weight(.medium))
					.foregroundStyle(.secondary)
			}
			.padding()
			.background(Material.thin)
			.cornerRadius(8)
			.shadow(radius: 10)
		}
	}
	
	@ViewBuilder
	private var playerList: some View {
		if let ownPlayer = gameInfo.players.firstElement(withID: userID) {
			let teams = Dictionary(grouping: gameInfo.players, by: \.teamID)
			let allyTeam = teams[ownPlayer.teamID]!
			let enemyTeams = teams
				.filter { $0.key != ownPlayer.teamID }
				.sorted(on: \.key.description)
			
			VStack(spacing: 10) {
				ForEach(allyTeam) {
					PlayerView(player: $0, ownPlayer: ownPlayer)
				}
				
				ForEach(enemyTeams, id: \.key) { teamID, team in
					Divider()
						.padding(.vertical, 5)
					
					ForEach(team) {
						PlayerView(player: $0, ownPlayer: ownPlayer)
					}
				}
			}
			.padding()
		}
	}
	
	struct PlayerView: View {
		let player: LiveGameInfo.PlayerInfo
		let ownPlayer: LiveGameInfo.PlayerInfo
		
		@LocalData var playerUser: User?
		@LocalData var summary: CareerSummary?
		@Environment(\.assets) private var assets
		@Environment(\.shouldAnonymize) private var shouldAnonymize
		
		init(player: LiveGameInfo.PlayerInfo, ownPlayer: LiveGameInfo.PlayerInfo) {
			self.player = player
			self.ownPlayer = ownPlayer
			self._playerUser = .init(id: player.id)
			self._summary = .init(id: player.id)
		}
		
		var body: some View {
			let isAlly = player.teamID == ownPlayer.teamID
			let isSelf = player.id == ownPlayer.id
			let teamColor: Color = isAlly ? .valorantBlue : .valorantRed
			let relativeColor = isSelf ? .valorantSelf : teamColor
			let iconSize = 48.0
			
			HStack {
				if let agentID = player.agentID {
					AgentImage.icon(agentID)
						.dynamicallyStroked(radius: 1.5, color: .white)
						.frame(width: iconSize, height: iconSize)
						.mask(Circle())
						.background(Circle().fill(relativeColor).opacity(0.5).padding(2))
						.padding(2)
						.overlay(Circle().strokeBorder(relativeColor, lineWidth: 2))
				}
				
				VStack(alignment: .leading, spacing: 4) {
					if !shouldAnonymize(player.id), let playerUser {
						HStack {
							Text(playerUser.gameName)
							Text("#\(playerUser.tagLine)")
								.foregroundStyle(.secondary)
						}
					}
					
					if let agentID = player.agentID {
						let agentName = assets?.agents[agentID]?.displayName
						Text(agentName ?? "Unknown Agent!")
							.fontWeight(.semibold)
					}
				}
				
				Spacer()
				
				if !isSelf {
					TransparentNavigationLink {
						MatchListView(userID: player.id)
					} label: {
						Image(systemName: "person.crop.circle.fill")
							.padding(.horizontal, 4)
					}
				}
				
				RankInfoView(summary: summary, size: iconSize)
			}
			.accentColor(relativeColor)
			.withLocalData($playerUser, id: player.id)
			.withLocalData($summary, id: player.id, shouldAutoUpdate: true)
		}
	}
}

extension EnvironmentValues {
	var anonymization: AnonymizationMode {
		get { self[AnonymizationModeKey.self] }
		set { self[AnonymizationModeKey.self] = newValue }
	}
	
	var shouldAnonymize: (Player.ID) -> Bool {
		anonymization.shouldAnonymize(_:)
	}
	
	private enum AnonymizationModeKey: EnvironmentKey {
		static let defaultValue = AnonymizationMode.none
	}
}

extension View {
	func anonymizing(additionally mode: AnonymizationMode) -> some View {
		transformEnvironment(\.anonymization) { $0 = $0.merging(mode) }
	}
}

enum AnonymizationMode {
	case all
	case some(Set<Player.ID>)
	case none
	
	func merging(_ other: Self) -> Self {
		switch (self, other) {
		case (.all, _), (_, .all):
			return .all
		case (.none, let other), (let other, .none):
			return other
		case (.some(let p1), .some(let p2)):
			return .some(p1.union(p2))
		}
	}
	
	func shouldAnonymize(_ player: Player.ID) -> Bool {
		switch self {
		case .all:
			return true
		case .some(let anonymized):
			return anonymized.contains(player)
		case .none:
			return false
		}
	}
}

#if DEBUG
struct LiveMatchView_Previews: PreviewProvider {
	static var previews: some View {
		LiveMatchView(
			gameInfo: PreviewData.liveGameInfo,
			userID: PreviewData.userID
		)
		.withToolbar()
	}
}
#endif
