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
			Text("Active Contract")
				.font(.headline)
				.frame(maxWidth: .infinity, alignment: .leading)
			
			GroupBox {
				// wish we could use guard statements…
				if let activeContract = contracts.details.activeSpecialContract {
					if let info = assets?.contracts[activeContract] {
						if let contract = contracts.details.contracts.firstElement(withID: activeContract) {
							overview(for: ContractData(contract: contract, info: info))
						} else {
							Text("Missing progress for contract!")
						}
					} else {
						Text("Unknown contract!")
					}
				} else {
					Text("No contract active!")
						.foregroundColor(.secondary)
				}
				
				Divider()
				
				NavigationLink(destination: ContractChooser(details: contracts.details)) {
					HStack {
						Text("Switch Contract")
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
							Text("\(currentXP) / \(data.totalXP) XP")
								.font(.footnote)
						} else {
							Text("Contract complete!")
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
			title: "Uncategorized Missions",
			missions: contracts.unknown
		)
		
		CurrentMissionsList(
			title: "Daily Missions",
			missions: contracts.dailies,
			countdownTarget: contracts.dailyRefresh
		)
		
		CurrentMissionsList(
			title: "Weekly Missions",
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
			
			UpcomingMissionsList(
				title: "Queued-Up Weeklies",
				missions: upcomingMissions.prefix(upTo: futureStart)
			)
			UpcomingMissionsList(
				title: "Future Weeklies",
				missions: upcomingMissions.suffix(from: futureStart)
			)
		}
	}
}

#if DEBUG
struct ContractDetailsView_Previews: PreviewProviderWithAssets {
	static func previews(assets: AssetCollection) -> some View {
		RefreshableBox(title: "Missions", isExpanded: .constant(true)) {
			ContractDetailsView(contracts: .init(details: PreviewData.contractDetails, assets: assets, config: PreviewData.gameConfig))
		} refresh: { _ in }
		.forPreviews()
	}
}
#endif
