import SwiftUI
import ValorantAPI

struct ContractDetailsView: View {
	var contracts: ResolvedContracts
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		contractInfo
		currentMissionsInfo
		upcomingMissionsInfo
	}
	
	@ViewBuilder
	var contractInfo: some View {
		Divider()
		
		VStack {
			Text("Active Contract", comment: "Missions Box: header")
				.font(.headline)
				.frame(maxWidth: .infinity, alignment: .leading)
			
			GroupBox {
				// wish we could use guard statements…
				if let activeContract = contracts.details.activeSpecialContract {
					if let info = assets?.contracts[activeContract] {
						if let contract = contracts.details.contracts.firstElement(withID: activeContract) {
							overview(for: ContractData(contract: contract, info: info))
						} else {
							Text("Missing progress for contract!", comment: "Missions Box")
						}
					} else {
						Text("Unknown contract!", comment: "Missions Box")
							.foregroundStyle(.secondary)
					}
				} else {
					Text("No contract active!", comment: "Missions Box")
						.foregroundStyle(.secondary)
				}
				
				Divider()
				
				NavigationLink(destination: ContractChooser(details: contracts.details)) {
					HStack {
						Text("Switch Contract", comment: "Missions Box: button")
						Spacer()
						Image(systemName: "chevron.right")
					}
				}
			}
		}
		.padding()
	}
	
	@ViewBuilder
	func overview(for data: ContractData) -> some View {
		VStack(alignment: .leading) {
			HStack {
				if let id = data.info.content.agentID {
					SquareAgentIcon(agentID: id)
						.frame(height: 64)
				}
				
				VStack(alignment: .leading) {
					Text(data.info.displayName)
						.fontWeight(.semibold)
					
					HStack {
						let currentXP = data.contract.progression.totalEarned
						
						if !data.isComplete {
							Text("\(currentXP) / \(data.totalXP) XP", comment: "Missions Box")
								.font(.footnote)
						} else {
							Text("Contract complete!", comment: "Missions Box")
						}
					}
					.foregroundColor(.secondary)
				}
				
				Spacer()
				
				ContractLevelProgressView(data: data)
			}
			
			ContractProgressBar(data: data)
		}
	}
	
	@ViewBuilder
	var currentMissionsInfo: some View {
		CurrentMissionsList(
			title: Text("Uncategorized Missions", comment: "Missions Box: header, shown when a mission is not daily or weekly (should not happen unless Riot changes something)"),
			missions: contracts.unknown
		)
		
		CurrentMissionsList(
			title: Text("Daily Missions", comment: "Missions Box: header"),
			missions: contracts.dailies,
			countdownTarget: contracts.dailyRefresh
		)
		
		CurrentMissionsList(
			title: Text("Weekly Missions", comment: "Missions Box: header"),
			missions: contracts.weeklies,
			countdownTarget: contracts.weeklyRefresh
		)
	}
	
	@ViewBuilder
	var upcomingMissionsInfo: some View {
		if let upcomingMissions = contracts.upcomingMissions {
			let now = Date.now
			let futureStart = upcomingMissions.firstIndex { $0.activationDate! > now }
				?? upcomingMissions.endIndex
			
			UpcomingMissionsList(missions: upcomingMissions.prefix(upTo: futureStart)) {
				Text("\($0) Queued-Up Weeklies", comment: "Missions Box: always at least 3")
			}
			UpcomingMissionsList(missions: upcomingMissions.suffix(from: futureStart)) {
				Text("\($0) Future Weeklies", comment: "Missions Box: always at least 3")
			}
		}
	}
}

#if DEBUG
struct ContractDetailsView_Previews: PreviewProvider, PreviewProviderWithAssets {
	static func previews(assets: AssetCollection) -> some View {
		RefreshableBox(title: "Missions", isExpanded: .constant(true)) {
			ContractDetailsView(contracts: PreviewData.resolvedContracts)
		} refresh: { _ in }
		.forPreviews()
	}
}
#endif
