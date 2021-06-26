import SwiftUI
import ValorantAPI

struct AgentSelectContainer: View {
	let matchID: Match.ID
	let user: User
	@State var pregameInfo: LivePregameInfo?
	@State var users: [User.ID: User]?
	@State var inventory: Inventory?
	
	@State private var hasEnded = false
	@State private var isShowingEndedAlert = false
	
	@Environment(\.valorantLoad) private var load
	@Environment(\.presentationMode) @Binding private var presentationMode
	
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
			await load {
				users = .init(values: try await $0.getUsers(for: userIDs))
			}
		}
		.task {
			guard inventory == nil else { return }
			await load {
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
		await load {
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
	@Environment(\.assets) private var assets
	
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
						
						AgentPickerView(pregameInfo: $pregameInfo, user: user, inventory: inventory)
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
			
			Text("\(pregameInfo.team.id.rawID) Team")
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
					let agentName = assets?.agents[player.agentID!]?.displayName
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
		AgentSelectContainer(
			matchID: PreviewData.pregameInfo.id,
			user: PreviewData.user,
			pregameInfo: PreviewData.pregameInfo,
			users: PreviewData.pregameUsers,
			inventory: PreviewData.inventory
		)
		.withToolbar()
		.inEachColorScheme()
		.inEachOrientation()
		
		AgentSelectContainer(matchID: Match.ID(), user: PreviewData.user)
	}
}
#endif
