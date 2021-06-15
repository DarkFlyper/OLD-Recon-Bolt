import SwiftUI
import ValorantAPI

struct AgentSelectContainer: View {
	@EnvironmentObject private var loadManager: ValorantLoadManager
	
	let matchID: Match.ID
	let user: User
	@State var pregameInfo: LivePregameInfo?
	@State var users: [User.ID: User]?
	
	var body: some View {
		VStack {
			if let pregameInfo = pregameInfo, let users = users {
				AgentSelectView(pregameInfo: pregameInfo, user: user, users: users)
			} else {
				ProgressView()
			}
		}
		.task {
			while !Task.isCancelled {
				await update()
				await Task.sleep(seconds: 1, tolerance: 0.1)
			}
		}
		.navigationTitle("Agent Select")
	}
	
	private func update() async {
		await loadManager.load {
			let info = try await $0.getLivePregameInfo(matchID)
			pregameInfo = info
			
			if users == nil {
				let userIDs = info.team.players.map(\.id)
				users = .init(values: try await $0.getUsers(for: userIDs))
			}
		}
	}
}

struct AgentSelectView: View {
	@EnvironmentObject private var loadManager: ValorantLoadManager
	@EnvironmentObject private var assetManager: AssetManager
	
	let pregameInfo: LivePregameInfo
	let user: User
	let users: [User.ID: User]
	
	var body: some View {
		VStack {
			hero
			
			ScrollView {
				VStack {
					VStack {
						ForEach(pregameInfo.team.players) { player in
							playerView(for: player)
						}
					}
					.padding()
				}
			}
		}
	}
	
	@ViewBuilder
	private var hero: some View {
		ZStack {
			MapImage.splash(pregameInfo.mapID)
				.aspectRatio(contentMode: .fill)
				.frame(height: 200)
				.clipped()
				.overlay(MapImage.Label(mapID: pregameInfo.mapID).padding(6))
			
			VStack(spacing: 10) {
				if let queueID = pregameInfo.queueID {
					Text(queueID.name)
						.fontWeight(.medium)
						.foregroundStyle(.secondary)
				}
				
				let remainingSeconds = Int(pregameInfo.timeRemainingInPhase.rounded())
				Text("\(Image(systemName: "timer")) \(remainingSeconds)")
					.fontWeight(.bold)
					.font(.title2)
					.monospacedDigit()
					.foregroundStyle(.primary)
					.drawingGroup()
				
				Text("\(pregameInfo.team.id.rawValue) Team")
					.foregroundColor(pregameInfo.team.id.color)
			}
			.padding()
			.background(Material.ultraThin)
			.cornerRadius(8)
			.shadow(radius: 10)
		}
	}
	
	@ViewBuilder
	private func playerView(for player: LivePregameInfo.PlayerInfo) -> some View {
		let relativeColor = player.id == user.id ? Color.valorantSelf : .valorantBlue
		let isLockedIn = player.isLockedIn
		let playerUser = users[player.id]!
		let iconSize: CGFloat = 48
		
		HStack {
			Group {
				if let agentID = player.agentID {
					AgentImage.displayIcon(agentID)
						.dynamicallyStroked(radius: 2, color: .white)
				} else {
					Image(systemName: "questionmark")
						.font(.system(size: iconSize / 2, weight: .bold))
						.foregroundColor(.white)
						.opacity(0.25)
						.blendMode(.plusLighter)
				}
			}
			.frame(width: iconSize, height: iconSize)
			.background(relativeColor.opacity(isLockedIn ? 0.5 : 0.25))
			.mask(Circle())
			.padding(4)
			.overlay(
				Circle()
					.strokeBorder(relativeColor, lineWidth: isLockedIn ? 2 : 1)
					.opacity(isLockedIn ? 1 : 0.75)
			)
			
			VStack(alignment: .leading, spacing: 4) {
				if !player.identity.isIncognito {
					HStack {
						Text(playerUser.gameName)
						Text("#\(playerUser.tagLine)")
							.foregroundColor(.secondary)
					}
				}
				
				if isLockedIn {
					let agentName = assetManager.assets?.agents[player.agentID!]?.displayName
					Text(agentName ?? "Unknown Agent!")
						.fontWeight(.semibold)
				} else {
					Text("Picking…")
						.foregroundColor(.secondary)
				}
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			
			if player.id != user.id {
				NavigationLink(destination: UserView(for: playerUser)) {
					Image(systemName: "person.crop.circle.fill")
						.padding(.horizontal, 4)
				}
			}
		}
	}
}

#if DEBUG
struct AgentSelectView_Previews: PreviewProvider {
	static var previews: some View {
		AgentSelectContainer(matchID: Match.ID(), user: PreviewData.user)
			.withMockValorantLoadManager()
		
		AgentSelectContainer(
			matchID: PreviewData.pregameInfo.id,
			user: PreviewData.user,
			pregameInfo: PreviewData.pregameInfo,
			users: PreviewData.pregameUsers
		)
		.withToolbar()
		.inEachColorScheme()
		.withMockValorantLoadManager()
		.withPreviewAssets()
	}
}
#endif
