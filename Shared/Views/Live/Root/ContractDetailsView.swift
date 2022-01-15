import SwiftUI
import ValorantAPI

typealias MissionWithInfo = (mission: Mission, info: MissionInfo?)

struct ContractDetailsView: View {
	var details: ContractDetails
	
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
				if let activeContract = details.activeSpecialContract {
					if let info = assets?.contracts[activeContract] {
						if let contract = details.contracts.firstElement(withID: activeContract) {
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
				
				NavigationLink(destination: ContractChooser(details: details)) {
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
				
				ContractLevelProgressView(data: data)
				
				VStack(alignment: .leading) {
					Text(data.info.displayName)
						.fontWeight(.semibold)
					
					HStack {
						if let nextLevel = data.nextLevel {
							let xpProgress = data.contract.progressionTowardsNextLevel
							let xpGoal = nextLevel.info.xp
							
							Text("\(xpProgress) / \(xpGoal) XP")
								.font(.footnote)
								.foregroundColor(.secondary)
						} else {
							Text("Max level reached!")
								.foregroundColor(.secondary)
						}
					}
				}
				
				Spacer()
			}
			
			ContractProgressBar(data: data)
		}
	}
	
	@ViewBuilder
	var currentMissionsInfo: some View {
		let missions: [MissionWithInfo] = details.missions
			.map { ($0, assets?.missions[$0.id]) }
		
		let dailies = missions.filter { $0.info?.type == .daily }
		let weeklies = missions.filter { $0.info?.type == .weekly }
		let covered = Set((dailies + weeklies).map(\.mission.id))
		let unknown = missions.filter { !covered.contains($0.mission.id) }
		
		CurrentMissionsList(
			title: "Uncategorized Missions",
			missions: unknown
		)
		
		CurrentMissionsList(
			title: "Daily Missions",
			missions: dailies,
			countdownTarget: dailies.first?.mission.expirationTime
		)
		
		CurrentMissionsList(
			title: "Weekly Missions",
			missions: weeklies,
			countdownTarget: details.missionMetadata.weeklyRefillTime
		)
	}
	
	@ViewBuilder
	var upcomingMissionsInfo: some View {
		if let upcomingMissions = upcomingMissions() {
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
	
	private func upcomingMissions() -> [MissionInfo]? {
		guard
			let assets = assets,
			let checkpointDate = [
				// weekly checkpoint may still be in the last act—let's take the later of that and the current act's start
				details.missionMetadata.weeklyCheckpoint,
				assets.seasons.currentAct()?.timeSpan.start,
			].compacted().max()
		else { return nil }
		
		let checkpoint = Calendar.current.date(
			byAdding: .day,
			value: 10, // overshoot by a bit—7 days might cause weird issues with DST and stuff
			// the weekly checkpoint is one week too early for us—we want the missions after the ones we're currently on
			to: checkpointDate
		)!
		
		return assets.missions.values
			.filter { $0.type == .weekly }
			// all weeklies have activation dates
			.filter { $0.activationDate! >= checkpoint }
			.sorted(on: \.activationDate!)
	}
}

#if DEBUG
struct ContractDetailsView_Previews: PreviewProvider {
    static var previews: some View {
		RefreshableBox(title: "Missions", refreshAction: {}) {
			ContractDetailsView(details: PreviewData.contractDetails)
		}
		.forPreviews()
		.inEachColorScheme()
    }
}
#endif
