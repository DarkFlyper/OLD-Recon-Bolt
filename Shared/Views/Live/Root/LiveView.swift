import SwiftUI
import ValorantAPI
import HandyOperators

struct LiveView: View {
	let userID: User.ID
	@State var contractDetails: ContractDetails?
	@State var activeMatch: ActiveMatch?
	
	@Environment(\.valorantLoad) private var load
	
	var body: some View {
		ScrollView {
			VStack(spacing: 20) {
				LiveGameBox(userID: userID, activeMatch: activeMatch, refreshAction: loadLiveGameDetails)
				
				missionsBox
			}
			.padding()
			.compositingGroup() // avoid shadows overlapping other boxes
			.shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
		}
		.refreshable(action: refresh)
		.task(refresh)
		.background(Color(.systemGroupedBackground))
		.navigationTitle("Live")
	}
	
	func refresh() async {
		// load both independently
		// TODO: change once `async let _ = ...` is fixed
		async let contractUpdate: Void = loadContractDetails()
		async let liveGameUpdate: Void = loadLiveGameDetails()
		_ = await (contractUpdate, liveGameUpdate)
	}
	
	var missionsBox: some View {
		RefreshableBox(title: "Missions", refreshAction: loadContractDetails) {
			if let details = contractDetails {
				ContractDetailsView(details: details)
			} else {
				Divider()
				
				GroupBox {
					Text("Missions not loaded!")
						.foregroundColor(.secondary)
				}
				.padding(16)
			}
		}
	}
	
	func loadContractDetails() async {
		await load {
			contractDetails = try await $0.getContractDetails()
		}
	}
	
	func loadLiveGameDetails() async {
		await load { client in
			async let liveGame = client.getLiveMatch(inPregame: false)
			async let livePregame = client.getLiveMatch(inPregame: true)
			
			if let match = try await liveGame {
				activeMatch = .init(id: match, inPregame: false)
			} else if let match = try await livePregame {
				activeMatch = .init(id: match, inPregame: true)
			} else {
				activeMatch = nil
			}
		}
	}
	
	struct ActiveMatch {
		var id: Match.ID
		var inPregame: Bool
	}
}

#if DEBUG
struct LiveView_Previews: PreviewProvider {
	static var previews: some View {
		LiveView(
			userID: PreviewData.userID,
			contractDetails: PreviewData.contractDetails
		)
		.withToolbar()
		.inEachColorScheme()
	}
}
#endif
