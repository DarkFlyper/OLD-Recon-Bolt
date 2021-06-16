import SwiftUI
import ValorantAPI

struct AgentSelectContainer: View {
	@EnvironmentObject private var loadManager: ValorantLoadManager
	
	let matchID: Match.ID
	let user: User
	@State var pregameInfo: LivePregameInfo?
	@State var users: [User.ID: User]?
	@State var inventory: Inventory?
	
	var body: some View {
		VStack {
			if let pregameInfo = Binding($pregameInfo), let users = users, let inventory = inventory {
				AgentSelectView(pregameInfo: pregameInfo, user: user, users: users, inventory: inventory)
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
			async let inventory = try await $0.getInventory(for: user.id)
			let info = try await $0.getLivePregameInfo(matchID)
			pregameInfo = info
			
			if users == nil {
				let userIDs = info.team.players.map(\.id)
				users = .init(values: try await $0.getUsers(for: userIDs))
			}
			
			self.inventory = try await inventory
		}
	}
}

struct AgentSelectView: View {
	@EnvironmentObject private var loadManager: ValorantLoadManager
	@EnvironmentObject private var assetManager: AssetManager
	
	@Binding
	var pregameInfo: LivePregameInfo
	let user: User
	let users: [User.ID: User]
	let inventory: Inventory
	
	var body: some View {
		ZStack(alignment: .top) {
			ScrollView {
				VStack(spacing: 0) {
					hero
					
					VStack {
						VStack {
							ForEach(pregameInfo.team.players) { player in
								playerView(for: player)
							}
						}
						.padding()
						
						Divider()
						
						agentSelectionView
					}
				}
			}
			
			infoBox
				.padding()
		}
		.navigationBarTitleDisplayMode(.inline)
	}
	
	@ViewBuilder
	private var hero: some View {
		MapImage.splash(pregameInfo.mapID)
			.aspectRatio(contentMode: .fill)
			.frame(height: 150)
			.clipped()
			// TODO: this doesn't do anything—probably a bug?
			//.ignoresSafeArea()
			.overlay(MapImage.Label(mapID: pregameInfo.mapID).padding(6))
	}
	
	@ViewBuilder
	private var infoBox: some View {
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
		.background(Material.thin)
		.cornerRadius(8)
		.shadow(radius: 10)
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
						.dynamicallyStroked(radius: 1.5, color: .white)
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
	
	@ViewBuilder
	private var agentSelectionView: some View {
		let ownPlayer = pregameInfo.team.players.first { $0.id == user.id }!
		let alreadyLocked = Set(
			pregameInfo.team.players
				.filter(\.isLockedIn)
				.filter { $0.id != user.id }
				.map { $0.agentID! }
		)
		
		VStack(spacing: 24) {
			let selectedAgentID = ownPlayer.agentID
			
			Button(role: nil) {
				await loadManager.load {
					pregameInfo = try await $0.lockInAgent(selectedAgentID!, in: pregameInfo.id)
				}
			} label: {
				let agentName = selectedAgentID
					.flatMap { assetManager.assets?.agents[$0] }?
					.displayName
				
				Text(agentName.map { "Lock In \($0)" } ?? "Lock In")
					.bold()
			}
			.disabled(selectedAgentID == nil || alreadyLocked.contains(selectedAgentID!))
			.controlProminence(.increased)
			.buttonStyle(.bordered)
			
			if let agents = assetManager.assets?.agents.values {
				let sortedAgents = agents.sorted(on: \.displayName)
					.movingToFront { inventory.agentsIncludingStarters.contains($0.id) }
				
				let agentSize = 50.0
				let gridSpacing = 12.0
				LazyVGrid(columns: [.init(
					.adaptive(minimum: agentSize, maximum: agentSize),
					spacing: gridSpacing, alignment: .center
				)], spacing: gridSpacing) {
					ForEach(sortedAgents) { agent in
						agentButton(
							for: agent,
							selectedAgentID: selectedAgentID,
							isTaken: alreadyLocked.contains(agent.id)
						)
					}
				}
				.padding(4)
			}
		}
		.disabled(ownPlayer.isLockedIn)
		.padding()
	}
	
	@ViewBuilder
	func agentButton(for agent: AgentInfo, selectedAgentID: Agent.ID?, isTaken: Bool) -> some View {
		let ownsAgent = inventory.agentsIncludingStarters.contains(agent.id)
		Button(role: nil) {
			await loadManager.load {
				pregameInfo = try await $0.selectAgent(agent.id, in: pregameInfo.id)
			}
		} label: {
			let isSelected = agent.id == selectedAgentID
			let lineWidth = isSelected ? 2.0 : 1.0
			let cornerRadius = 8.0
			let backgroundInset = 2.0
			
			agent.displayIcon.image
				.resizable()
				.aspectRatio(1, contentMode: .fit)
				.dynamicallyStroked(radius: 1.5, color: .white)
				.compositingGroup()
				.opacity(ownsAgent ? 1 : 0.5)
				.opacity(isTaken ? 0.8 : 1)
				.cornerRadius(cornerRadius)
				.background(
					RoundedRectangle(cornerRadius: cornerRadius - backgroundInset)
						.fill(.secondary)
						.padding(backgroundInset)
				)
				.overlay(
					RoundedRectangle(cornerRadius: cornerRadius + lineWidth)
						.strokeBorder(lineWidth: lineWidth)
						.padding(-lineWidth)
				)
				.foregroundStyle(isSelected ? Color.valorantSelf : Color.accentColor)
		}
		.disabled(!ownsAgent || isTaken)
	}
}

#if DEBUG
struct AgentSelectView_Previews: PreviewProvider {
	static var previews: some View {
		//AgentSelectContainer(matchID: Match.ID(), user: PreviewData.user)
		//	.withMockValorantLoadManager()
		
		AgentSelectContainer(
			matchID: PreviewData.pregameInfo.id,
			user: PreviewData.user,
			pregameInfo: PreviewData.pregameInfo,
			users: PreviewData.pregameUsers,
			inventory: PreviewData.inventory
		)
		.withToolbar()
		//.inEachColorScheme()
		.withMockValorantLoadManager()
		.withPreviewAssets()
		//.previewInterfaceOrientation(.landscapeRight)
	}
}
#endif
