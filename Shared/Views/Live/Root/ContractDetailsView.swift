import SwiftUI
import ValorantAPI

struct ContractDetailsView: View {
	var contracts: ResolvedContracts
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		dailyProgress
		currentMissionsInfo
		upcomingMissionsInfo
	}
	
	var dailyProgress: some View {
		Box(
			title: Text("Daily Checkpoints", comment: "Missions Box: header"),
			countdownTarget: contracts.dailyRefresh
		) {
			DailyTicketView(milestones: contracts.daily.milestones)
				.frame(maxWidth: 420)
		}
	}
	
	@ViewBuilder
	var currentMissionsInfo: some View {
		if !contracts.weeklies.isEmpty {
			Divider()
			
			Box(
				title: Text("Weekly Missions", comment: "Missions Box: header"),
				countdownTarget: contracts.weeklyRefresh
			) {
				ForEach(contracts.weeklies) { mission in
					if let info = mission.info {
						MissionView(missionInfo: info, mission: mission.mission)
					} else {
						Text("Unknown mission!")
							.foregroundStyle(.secondary)
					}
				}
			}
		}
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
	
	private struct Box<Content: View>: View {
		let title: Text
		let countdownTarget: Date?
		@ViewBuilder var content: Content
		
		var body: some View {
			VStack(spacing: 16) {
				HStack(alignment: .lastTextBaseline) {
					title
						.font(.headline)
						.multilineTextAlignment(.leading)
					
					Spacer()
					
					Group {
						if let countdownTarget {
							CountdownText(target: countdownTarget)
							Image(systemName: "clock")
						}
					}
					.font(.caption.weight(.medium))
					.foregroundStyle(.secondary)
				}
				
				GroupBox {
					content
				}
			}
			.padding(16)
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
