import SwiftUI
import ValorantAPI

private typealias MissionWithInfo = (mission: Mission, info: MissionInfo?)

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
				if let activeContract = details.activeSpecialContract {
					if let info = assets?.contracts[activeContract] {
						VStack(spacing: 8) {
							if
								info.content.relationType == .agent,
								let rawID = info.content.relationID,
								let id = Agent.ID(rawID)
							{
								let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)
								AgentImage.icon(id)
									.background(Color(.lightGray).opacity(0.5))
									.clipShape(shape)
									.overlay { shape.stroke(Color(.lightGray)) }
									.frame(height: 64)
							}
							
							Text(info.displayName)
								.fontWeight(.semibold)
						}
						
						if let contract = details.contracts.first { $0.id == activeContract } {
							Divider()
							
							details(for: contract, using: info)
						}
					} else {
						Text("Unknown contract!")
					}
				} else {
					Text("No contract active!")
						.foregroundColor(.secondary)
				}
			}
		}
		.padding()
	}
	
	@ViewBuilder
	func details(for contract: Contract, using info: ContractInfo) -> some View {
		let levels = info.content.chapters.flatMap(\.levels)
		let levelNumber = contract.levelReached
		
		VStack(spacing: 8) {
			Text("Current Level (out of \(levels.count))")
				.font(.subheadline.weight(.medium))
			
			HStack {
				if levelNumber < levels.count {
					let nextLevel = levels[levelNumber]
					ZStack {
						levelProgressView(
							fractionComplete: Double(contract.progressionTowardsNextLevel) / Double(nextLevel.xp)
						)
						
						Text("\(levelNumber)")
							.font(.footnote)
					}
					
					Text("\(contract.progressionTowardsNextLevel) / \(nextLevel.xp) XP")
						.font(.footnote)
				} else {
					Text("Max level reached!")
						.foregroundColor(.secondary)
				}
			}
		}
		
		Divider()
		
		VStack(spacing: 8) {
			let currentXP = contract.progression.totalEarned
			let totalXP = levels.map(\.xp).reduce(0, +)
			Text("Overall Progress")
				.font(.subheadline.weight(.medium))
			
			ProgressView(
				value: Double(currentXP),
				total: Double(totalXP),
				label: { EmptyView() },
				currentValueLabel: { Text("\(currentXP)/\(totalXP) XP") }
			)
		}
	}
	
	@ViewBuilder
	func levelProgressView(fractionComplete: Double) -> some View {
		CircularProgressView(lineWidth: 4) {
			CircularProgressLayer(
				end: fractionComplete,
				shouldKnockOutSurroundings: true,
				color: .accentColor
			)
		} base: {
			Color.gray.opacity(0.25)
		}
		.frame(width: 24, height: 24)
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
		guard let assets = assets else { return nil }
		
		let checkpoint = Calendar.current.date(
			byAdding: .day,
			value: 10, // overshoot by a bit—7 days might cause weird issues with DST and stuff
			// the weekly checkpoint is one week too early for us—we want the missions after the ones we're currently on
			to: details.missionMetadata.weeklyCheckpoint
				?? assets.seasons.currentAct()?.timeSpan.start
				?? .distantFuture
		)!
		
		return assets.missions.values
			.filter { $0.type == .weekly }
			// all weeklies have activation dates
			.filter { $0.activationDate! >= checkpoint }
			.sorted(on: \.activationDate!)
	}
}

private struct CurrentMissionsList: View {
	var title: String
	var missions: [MissionWithInfo]
	var countdownTarget: Date? = nil
	
	var body: some View {
		if !missions.isEmpty {
			Divider()
			
			VStack(spacing: 16) {
				HStack(alignment: .lastTextBaseline) {
					Text(title)
						.font(.headline)
						.multilineTextAlignment(.leading)
					
					Spacer()
					
					Group {
						if let countdownTarget = countdownTarget {
							CountdownText(target: countdownTarget)
							Image(systemName: "clock")
						}
					}
					.font(.caption.weight(.medium))
					.foregroundStyle(.secondary)
				}
				
				GroupBox {
					ForEach(missions, id: \.mission.id) { mission, missionInfo in
						if let missionInfo = missionInfo {
							MissionView(missionInfo: missionInfo, mission: mission)
						} else {
							Text("Unknown mission!")
						}
					}
				}
			}
			.padding(16)
		}
	}
}

private struct UpcomingMissionsList: View {
	var title: String
	var missions: ArraySlice<MissionInfo>
	@State var isExpanded = false
	
	private static let dateFormatter = RelativeDateTimeFormatter()
	
	var body: some View {
		if !missions.isEmpty {
			Divider()
			
			VStack(spacing: 16) {
				let totalXP = missions.map(\.xpGrant).reduce(0, +)
				
				Button {
					withAnimation { isExpanded.toggle() }
				} label: {
					HStack {
						Image(systemName: "chevron.down")
							.rotationEffect(.degrees(isExpanded ? 0 : -90))
						
						Text("\(missions.count) \(title)")
							.multilineTextAlignment(.leading)
						
						Spacer()
						
						Text("+\(totalXP) XP")
							.font(.caption.weight(.medium))
							.foregroundStyle(.secondary)
					}
					.font(.headline)
				}
				
				if isExpanded {
					let byActivation = missions.chunked(on: \.activationDate!)
					ForEach(byActivation, id: \.0) { (date, missions) in
						GroupBox {
							Text(date, formatter: Self.dateFormatter)
								.font(.subheadline.weight(.semibold))
							
							Divider()
							
							VStack(spacing: 8) {
								ForEach(missions) {
									MissionView(missionInfo: $0)
								}
							}
						}
					}
				}
			}
			.padding(16)
		}
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
