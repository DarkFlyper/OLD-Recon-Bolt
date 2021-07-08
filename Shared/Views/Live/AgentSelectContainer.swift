import SwiftUI
import ValorantAPI
import HandyOperators

struct AgentSelectContainer: View {
	let matchID: Match.ID
	let user: User
	@State var pregameInfo: LivePregameInfo?
	@State var inventory: Inventory?
	
	@State private var hasEnded = false
	@State private var isShowingEndedAlert = false
	
	@Environment(\.valorantLoad) private var load
	@Environment(\.presentationMode) @Binding private var presentationMode
	
	var body: some View {
		VStack {
			if let pregameInfo = Binding($pregameInfo), let inventory = inventory {
				AgentSelectView(
					pregameInfo: pregameInfo,
					user: user,
					inventory: inventory
				)
			} else {
				ProgressView()
				Text("Loading Agent Select…")
			}
		}
		.task {
			while !Task.isCancelled, !hasEnded {
				await update()
				await Task.sleep(seconds: 1, tolerance: 0.1)
			}
		}
		.valorantLoadTask(id: pregameInfo == nil) {
			guard let pregameInfo = pregameInfo else { return }
			let userIDs = pregameInfo.team.players.map(\.id)
			try await LocalDataProvider.shared.fetchUsers(for: userIDs, using: $0)
		}
		.valorantLoadTask {
			guard inventory == nil else { return }
			inventory = try await $0.getInventory(for: user.id)
		}
		.alert(
			"Agent Select Ended!",
			isPresented: $isShowingEndedAlert,
			actions: { Button("Exit") { presentationMode.dismiss() } },
			message: { Text("This game is no longer in agent select.") }
		)
		.navigationTitle("Agent Select")
		.navigationBarTitleDisplayMode(.inline)
	}
	
	private func update() async {
		await load {
			do {
				pregameInfo = try await $0.getLivePregameInfo(matchID) <- {
					LocalDataProvider.shared
						.store($0.team.players.map(\.identity))
				}
			} catch ValorantClient.APIError.badResponseCode(404, _, _) {
				hasEnded = true
				isShowingEndedAlert = true
			}
		}
	}
}

#if DEBUG
struct AgentSelectContainer_Previews: PreviewProvider {
	static var previews: some View {
		AgentSelectContainer(matchID: Match.ID(), user: PreviewData.user)
			.inEachColorScheme()
	}
}
#endif
