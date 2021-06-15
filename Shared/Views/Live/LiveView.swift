import SwiftUI
import ValorantAPI

struct LiveView: View {
	let user: User
	@State var contractDetails: ContractDetails?
	@State var activeMatch: ActiveMatch?
	
	@EnvironmentObject private var loadManager: ValorantLoadManager
	@EnvironmentObject private var assetManager: AssetManager
	
	var body: some View {
		ScrollView {
			VStack(spacing: 20) {
				Group {
					missionsBox
					
					liveGameBox
				}
				.background(Color(.tertiarySystemBackground))
				.cornerRadius(20)
				.shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
			}
			.padding()
		}
		.background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
		.onAppear {
			async { await refresh() }
		}
		.refreshable(action: refresh)
		.navigationTitle("Live")
	}
	
	func refresh() async {
		// load both independently
		// TODO: feels like there should be a better approach lol
		async let refresh1: Void = loadContractDetails()
		async let refresh2: Void = loadLiveGameDetails()
		await refresh1
		await refresh2
	}
	
	var missionsBox: some View {
		VStack(spacing: 0) {
			HStack {
				Text("Missions")
					.font(.title2)
					.fontWeight(.semibold)
				
				Spacer()
				
				Button(role: nil) { await loadContractDetails() } label: {
					Image(systemName: "arrow.clockwise")
				}
			}
			.padding()
			
			if let details = contractDetails {
				contractInfo(details: details)
			} else {
				Divider()
				
				Text("Missions not loaded!")
					.padding()
					.frame(maxWidth: .infinity)
			}
		}
	}
	
	var liveGameBox: some View {
		VStack(spacing: 0) {
			HStack {
				Text("Live Game")
					.font(.title2)
					.fontWeight(.semibold)
				
				Spacer()
				
				Button(role: nil, action: loadLiveGameDetails) {
					Image(systemName: "arrow.clockwise")
				}
				.disabled(true)
			}
			.padding()
			
			Divider()
			
			if let activeMatch = activeMatch {
				VStack(spacing: 20) {
					Text("Currently \(activeMatch.inPregame ? "in agent select" : "in-game")!")
					
					NavigationLink("\(activeMatch.inPregame ? "Agent Select" : "Details") \(Image(systemName: "chevron.right"))") {
						Text("heyyy")
					}
				}
				.padding()
			} else {
				Text("Not currently in a match!")
					.opacity(0.8)
					.padding()
			}
		}
	}
	
	func contractInfo(details: ContractDetails) -> some View {
		ForEach(details.missions) { mission in
			let _ = assert(mission.objectiveProgress.count == 1)
			let (objectiveID, progress) = mission.objectiveProgress.first!
			if
				let mission = assetManager.assets?.missions[mission.id],
				let objective = assetManager.assets?.objectives[objectiveID]
			{
				Divider()
				
				missionInfo(mission: mission, objective: objective, progress: progress)
			} else {
				Text("Unknown mission!")
			}
		}
	}
	
	func missionInfo(mission: MissionInfo, objective: ObjectiveInfo, progress: Int) -> some View {
		VStack {
			HStack(alignment: .lastTextBaseline) {
				Text(
					verbatim: objective.directive?
						.valorantLocalized(number: mission.progressToComplete)
						?? mission.displayName
						?? mission.title
						?? "<Unnamed Mission>"
				)
				.frame(maxWidth: .infinity, alignment: .leading)
				
				Text("+\(mission.xpGrant) XP")
					.font(.caption)
					.fontWeight(.medium)
					.opacity(0.8)
			}
			
			let toComplete = mission.progressToComplete
			ProgressView(
				value: Double(progress),
				total: Double(toComplete),
				label: { EmptyView() },
				currentValueLabel: { Text("\(progress)/\(toComplete)") }
			)
		}
		.padding()
	}
	
	func loadContractDetails() async {
		await loadManager.load {
			contractDetails = try await $0.getContractDetails(playerID: user.id)
		}
	}
	
	func loadLiveGameDetails() async {
		await loadManager.load { client in
			async let liveGameMatch = client.getLiveMatch(for: user.id, inPregame: false)
			async let livePregameMatch = client.getLiveMatch(for: user.id, inPregame: true)
			
			if let match = try await liveGameMatch {
				activeMatch = .init(id: match, inPregame: false)
			} else if let match = try await livePregameMatch {
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
		Group {
			LiveView(user: PreviewData.user, contractDetails: PreviewData.contractDetails)
				.withToolbar()
				.inEachColorScheme()
			
			LiveView(user: PreviewData.user, activeMatch: .init(id: Match.ID(), inPregame: true))
				.withToolbar()
			
			LiveView(user: PreviewData.user, activeMatch: .init(id: Match.ID(), inPregame: false))
				.withToolbar()
		}
		.withMockValorantLoadManager()
		.withPreviewAssets()
	}
}
#endif
