import SwiftUI
import ValorantAPI

struct AgentPickerView: View {
	@Binding
	var pregameInfo: LivePregameInfo
	let user: User
	let inventory: Inventory
	
	/// We can actually change our locked-in agent to a different one, but we want that functionality reasonably hidden.
	/// This achieves that by making it so you can only re-lock while holding down the lock in button
	@GestureState private var canRelock = false
	
	@Environment(\.valorantLoad) private var load
	@Environment(\.assets) private var assets
	
	var body: some View {
		let ownPlayer = pregameInfo.team.players.first { $0.id == user.id }!
		let gameModeInfo = assets?.gameModes[pregameInfo.modeID]
		let isVotingBased = gameModeInfo?.gameRuleOverride(for: .majorityVoteAgents) == true
		let takenAgents = isVotingBased ? [] : Set(
			pregameInfo.team.players
				.filter(\.isLockedIn)
				.filter { $0.id != user.id }
				.map { $0.agentID! }
		)
		
		let hasSelectedAgent = ownPlayer.isLockedIn && !canRelock
		
		VStack(spacing: 24) {
			let selectedAgentID = ownPlayer.agentID
			
			AsyncButton {
				await load {
					pregameInfo = try await $0.lockInAgent(selectedAgentID!, in: pregameInfo.id)
				}
			} label: {
				let agentName = selectedAgentID
					.flatMap { assets?.agents[$0] }?
					.displayName
				
				Text(agentName.map { "Lock In \($0)" } ?? "Lock In")
					.bold()
			}
			.controlProminence(.increased)
			.buttonStyle(.bordered)
			.disabled(selectedAgentID == nil || takenAgents.contains(selectedAgentID!))
			.disabled(hasSelectedAgent) // can't move this out because then it'd affect the relock gesture too
			.simultaneousGesture(holdGesture(isHolding: $canRelock))
			
			if let agents = assets?.agents.values {
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
							isTaken: takenAgents.contains(agent.id)
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
		AsyncButton {
			await load {
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
			agent.displayIcon.imageOrPlaceholder
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

private func holdGesture(isHolding: GestureState<Bool>) -> some Gesture {
	DragGesture(minimumDistance: 0)
		.updating(isHolding) { _, isHolding, _ in
			isHolding = true
		}
}
