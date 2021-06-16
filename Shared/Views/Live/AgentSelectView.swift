import SwiftUI
import ValorantAPI

struct AgentSelectContainer: View {
	@EnvironmentObject private var loadManager: ValorantLoadManager
	@Environment(\.presentationMode) @Binding private var presentationMode
	
	let matchID: Match.ID
	let user: User
	@State var pregameInfo: LivePregameInfo?
	@State var users: [User.ID: User]?
	@State var inventory: Inventory?
	
	@State private var hasEnded = false
	@State private var isShowingEndedAlert = false
	
	var body: some View {
		VStack {
			if let pregameInfo = Binding($pregameInfo), let users = users, let inventory = inventory {
				AgentSelectView(pregameInfo: pregameInfo, user: user, users: users, inventory: inventory)
			} else {
				ProgressView()
			}
		}
		.task {
			while !Task.isCancelled, !hasEnded {
				await update()
				await Task.sleep(seconds: 1, tolerance: 0.1)
			}
		}
		.task(id: pregameInfo == nil) {
			guard let pregameInfo = pregameInfo, users == nil else { return }
			let userIDs = pregameInfo.team.players.map(\.id)
			await loadManager.load {
				users = .init(values: try await $0.getUsers(for: userIDs))
			}
		}
		.task {
			guard inventory == nil else { return }
			await loadManager.load {
				inventory = try await $0.getInventory(for: user.id)
			}
		}
		.alert(
			"Game Has Ended!",
			isPresented: $isShowingEndedAlert,
			actions: { Button("Exit") { presentationMode.dismiss() } },
			message: { Text("This game is no longer running.") }
		)
		.navigationTitle("Agent Select")
		.navigationBarTitleDisplayMode(.inline)
	}
	
	private func update() async {
		await loadManager.load {
			do {
				pregameInfo = try await $0.getLivePregameInfo(matchID)
			} catch ValorantClient.APIError.badResponseCode(404, _, _) {
				hasEnded = true
				isShowingEndedAlert = true
			}
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
			
			Group {
				if pregameInfo.state == .provisioned {
					Text("Game Started")
				} else {
					let remainingSeconds = Int(pregameInfo.timeRemainingInPhase.rounded())
					Label("\(remainingSeconds)", systemImage: "timer")
						.monospacedDigit()
				}
			}
			.font(.title2.weight(.bold))
			.foregroundStyle(.primary)
			
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
			.mask(Circle())
			.padding(isLockedIn ? 1 : 0)
			.background(
				Circle()
					.fill(relativeColor)
					.opacity(isLockedIn ? 0.5 : 0.25)
					.padding(2)
			)
			.padding(2)
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
	
	/// We can actually change our locked-in agent to a different one, but we want that functionality reasonably hidden.
	/// This achieves that by making it so you can only re-lock while holding down the lock in button
	@GestureState private var canRelock = false
	
	@ViewBuilder
	private var agentSelectionView: some View {
		let ownPlayer = pregameInfo.team.players.first { $0.id == user.id }!
		let alreadyLocked = Set(
			pregameInfo.team.players
				.filter(\.isLockedIn)
				.filter { $0.id != user.id }
				.map { $0.agentID! }
		)
		
		let hasSelectedAgent = ownPlayer.isLockedIn && !canRelock
		
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
			.controlProminence(.increased)
			.buttonStyle(.bordered)
			.disabled(selectedAgentID == nil || alreadyLocked.contains(selectedAgentID!))
			.disabled(hasSelectedAgent) // can't move this out because then it'd affect the relock gesture too
			.simultaneousGesture(holdGesture(isHolding: $canRelock))
			
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
				.disabled(hasSelectedAgent)
			}
		}
		.disabled(pregameInfo.state != .agentSelectActive)
		.padding()
	}
	
	@ViewBuilder
	func agentButton(for agent: AgentInfo, selectedAgentID: Agent.ID?, isTaken: Bool) -> some View {
		let ownsAgent = inventory.agentsIncludingStarters.contains(agent.id)
		Button(role: nil) {
			await loadManager.load {
				pregameInfo = try await $0.pickAgent(
					agent.id, in: pregameInfo.id,
					shouldLock: canRelock // we can re-lock a different agent by simply sending the appropriate lock-in request
				)
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

private func holdGesture(isHolding: GestureState<Bool>) -> some Gesture {
	DragGesture(minimumDistance: 0)
		.updating(isHolding) { _, isHolding, _ in
			isHolding = true
		}
}
