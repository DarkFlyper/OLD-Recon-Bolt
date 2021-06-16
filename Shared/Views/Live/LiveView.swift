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
					liveGameBox
					
					missionsBox
				}
				.background(Color(.tertiarySystemBackground))
				.cornerRadius(20)
				.shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
			}
			.padding()
		}
		.refreshable(action: refresh)
		.task(refresh)
		.background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
		.navigationTitle("Live")
	}
	
	func refresh() async {
		// load both independently
		async let refreshes = (loadContractDetails(), loadLiveGameDetails())
		_ = await refreshes
	}
	
	var missionsBox: some View {
		box(title: "Missions", refreshAction: loadContractDetails) {
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
	
	func box<Content: View>(
		title: String,
		refreshAction: @escaping () async -> Void,
		@ViewBuilder content: () -> Content
	) -> some View {
		VStack(spacing: 0) {
			HStack {
				Text(title)
					.font(.title2)
					.fontWeight(.semibold)
				
				Spacer()
				
				Button(role: nil, action: refreshAction) {
					Image(systemName: "arrow.clockwise")
				}
			}
			.padding()
			
			content()
		}
	}
	
	var liveGameBox: some View {
		box(title: "Live Game", refreshAction: loadLiveGameDetails) {
			Divider()
			
			if let activeMatch = activeMatch {
				VStack(spacing: 20) {
					Text("Currently \(activeMatch.inPregame ? "in agent select" : "in-game")!")
					
					if activeMatch.inPregame {
						NavigationLink("Agent Select \(Image(systemName: "chevron.right"))") {
							AgentSelectContainer(matchID: activeMatch.id, user: user)
						}
					} else {
						NavigationLink("Details \(Image(systemName: "chevron.right"))") {
							Text("Not implemented yet!")
						}
						.disabled(true)
					}
				}
				.padding()
			} else {
				Text("Not currently in a match!")
					.foregroundColor(.secondary)
					.padding()
				
				Divider()
					.padding(.horizontal)
				
				HStack(spacing: 10) {
					if isAutoRefreshing {
						autoRefreshView
					}
					
					Toggle("Auto-Refresh", isOn: $isAutoRefreshing)
				}
				.padding()
			}
		}
	}
	
	@State var isAutoRefreshing = false
	@State var isAutoRefreshRunning = false
	
	@ViewBuilder
	var autoRefreshView: some View {
		let strokeStyle = StrokeStyle(lineWidth: 4, lineCap: .round)
		
		Circle()
			.trim(from: 0, to: isAutoRefreshRunning ? 1 : 1e-3)
			.scale(x: -1)
			.rotation(.degrees(90))
			.stroke(Color.accentColor, style: strokeStyle)
			.background(Circle().stroke(.quaternary, style: strokeStyle))
			.frame(width: 20, height: 20)
			.task {
				while !Task.isCancelled {
					withAnimation(.easeIn(duration: 0.1)) {
						isAutoRefreshRunning = true
					}
					
					await loadLiveGameDetails()
					if activeMatch != nil {
						isAutoRefreshing = false
					}
					
					let refreshInterval: TimeInterval = 5
					let tolerance: TimeInterval = 1
					withAnimation(.easeOut(duration: refreshInterval + tolerance)) {
						isAutoRefreshRunning = false
					}
					await Task.sleep(seconds: refreshInterval, tolerance: tolerance)
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
			LiveView(
				user: PreviewData.user,
				contractDetails: PreviewData.contractDetails,
				isAutoRefreshing: true, isAutoRefreshRunning: true
			)
			.withToolbar()
			//.inEachColorScheme()
			
			/*
			LiveView(user: PreviewData.user, activeMatch: .init(id: Match.ID(), inPregame: true))
				.withToolbar()
			
			LiveView(user: PreviewData.user, activeMatch: .init(id: Match.ID(), inPregame: false))
				.withToolbar()
			 */
		}
		.withMockValorantLoadManager()
		.withPreviewAssets()
	}
}
#endif
