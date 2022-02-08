import SwiftUI
import ValorantAPI
import HandyOperators

struct LiveView: View {
	let userID: User.ID
	@State var contractDetails: ContractDetails?
	@State var party: Party?
	@State var activeMatch: ActiveMatch?
	
	@Environment(\.valorantLoad) private var load
	@Environment(\.scenePhase) private var scenePhase
	
	var body: some View {
		ScrollView {
			VStack(spacing: 20) {
				LiveGameBox(userID: userID, party: $party, activeMatch: activeMatch, refreshAction: loadActiveMatch)
				
				missionsBox
			}
			.padding()
			.compositingGroup() // avoid shadows overlapping other boxes
			.shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
		}
		.refreshable(action: refresh)
		.task(refresh)
		.onSceneActivation(perform: refresh)
		.background(Color(.systemGroupedBackground))
		.navigationTitle("Live")
	}
	
	@Sendable
	func refresh() async {
		// load independently & concurrently
		// TODO: change once `async let _ = ...` is fixed
		async let contractUpdate: Void = loadContractDetails()
		async let activeMatchUpdate: Void = loadActiveMatch()
		async let partyUpdate: Void = loadParty()
		_ = await (contractUpdate, activeMatchUpdate, partyUpdate)
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
	
	func loadActiveMatch() async {
		await load {
			activeMatch = try await $0.getActiveMatch()
		}
	}
	
	func loadParty() async {
		await load {
			party = try await $0.getPartyInfo()
			if let party = party {
				LocalDataProvider.dataFetched(party)
				try await $0.fetchUsers(for: party.members.map(\.id))
			}
		}
	}
}

struct ActiveMatch: Hashable {
	var id: Match.ID
	var inPregame: Bool
}

extension ValorantClient {
	func getActiveMatch() async throws -> ActiveMatch? {
		async let liveGame = getLiveMatch(inPregame: false)
		async let livePregame = getLiveMatch(inPregame: true)
		
		if let match = try await liveGame {
			return .init(id: match, inPregame: false)
		} else if let match = try await livePregame {
			return .init(id: match, inPregame: true)
		} else {
			return nil
		}
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
