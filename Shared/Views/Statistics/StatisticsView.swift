import SwiftUI
import ValorantAPI
import UserDefault
import HandyOperators

@available(iOS 16.0, *)
struct StatisticsView: View {
	var user: User
	var matchList: MatchList
	
	@State var statistics: Statistics?
	@State var fetchedMatches: [MatchDetails] = []
	
	@UserDefault.State("StatisticsView.excludedQueues")
	var excludedQueues: Set<QueueID> = [
		.deathmatch, // average DM win rate is far from 50%
		.spikeRush,
		.custom,
		.escalation,
		.snowballFight
	] // no good data from these
	
	@UserDefault.State("StatisticsView.excludedAgents")
	var excludedAgents: Set<Agent.ID> = []
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		Form {
			if matchList.matches.contains(where: \.isRanked) {
				Section("Rank Rating Changes") {
					RankRatingChart(matches: matchList.matches)
						.listRowInsets(.init())
				}
			}
			
			LoadingSection(matchList: matchList, fetchedMatches: $fetchedMatches)
			
			filterSection()
			
			if let statistics {
				breakdowns(for: statistics)
					.font(.title3.weight(.medium))
			}
		}
		.navigationTitle("Statistics")
		.onChange(of: dataSourceHash) { _ in
			Task.detached(priority: .userInitiated) { [excludedQueues, excludedAgents, fetchedMatches] in
				let start = Date()
				print("computing!")
				let matches = fetchedMatches.filter { match in
					guard !excludedQueues.contains(match.matchInfo.queueID ?? .custom) else { return false }
					let player = match.players.firstElement(withID: user.id)!
					guard player.agentID.map(excludedAgents.contains(_:)) != true else { return false }
					return true
				}
				let stats = matches.isEmpty ? nil : Statistics(userID: user.id, matches: matches)
				print("computed in \(-start.timeIntervalSinceNow)")
				await MainActor.run {
					self.statistics = stats
				}
			}
		}
	}
	
	var dataSourceHash: Int {
		(Hasher() <- {
			$0.combine(fetchedMatches.map(\.id))
			$0.combine(excludedQueues)
			$0.combine(excludedAgents)
		}).finalize()
	}
	
	func filterSection() -> some View {
		Section {
			FilterPicker(
				title: String(localized: "Queues", comment: "Statistics filter: button"),
				allAllowedLabel: String(
					localized: "Any Queue",
					comment: "Statistics filter: shown when every queue is allowed"
				),
				allowedLabel: { String(
					localized: "\($0) queues selected",
					comment: "Statistics Filter: shown when not every queue is allowed"
				) },
				allowAllButton: String(
					localized: "Allow All Queues",
					defaultValue: "Allow All",
					comment: "Statistics Filter: button to allow all queues"
				),
				allowNoneButton: String(
					localized: "Exclude All Queues",
					defaultValue: "Exclude All",
					comment: "Statistics Filter: button to exclude all queues"
				),
				excluded: $excludedQueues
			)
			FilterPicker(
				title: String(localized: "Agents", comment: "Statistics filter: button"),
				allAllowedLabel: String(
					localized: "Any Agent",
					comment: "Statistics filter: shown when every agent is allowed"
				),
				allowedLabel: { String(
					localized: "\($0) agents selected",
					comment: "Statistics Filter: shown when not every agent is allowed"
				) },
				allowAllButton: String(
					localized: "Allow All Agents",
					defaultValue: "Allow All",
					comment: "Statistics Filter: button to allow all agents"
				),
				allowNoneButton: String(
					localized: "Exclude All Agents",
					defaultValue: "Exclude All",
					comment: "Statistics Filter: button to exclude all agents"
				),
				excluded: $excludedAgents
			)
		} header: {
			Text("Filter", comment: "Statistics Filter: title (section)")
		} footer: {
			if let statistics {
				let allowed = statistics.matches.count
				let filtered = fetchedMatches.count - allowed
				Text("Using data from \(allowed) match(es) (\(filtered) filtered out)", comment: "Statistics Filter")
			}
		}
	}
	
	@ViewBuilder
	func breakdowns(for statistics: Statistics) -> some View {
		detailsLink("Playtime Breakdown", systemImage: "clock", showBaseline: true) {
			PlaytimeView(statistics: statistics)
		} chart: {
			PlaytimeView.overview(statistics: statistics)
		}
		
		detailsLink("Hit Distribution", systemImage: "scope") {
			HitDistributionView(statistics: statistics)
		} chart: {
			HitDistributionView.overview(statistics: statistics)
		}
		
		detailsLink("Win Rate", systemImage: "medal", showBaseline: true) {
			WinRateView(statistics: statistics)
		} chart: {
			WinRateView.overview(statistics: statistics)
		}
	}
	
	func detailsLink<Destination: View, Chart: View>(
		_ title: LocalizedStringKey, systemImage: String,
		showBaseline: Bool = false,
		@ViewBuilder destination: @escaping () -> Destination,
		@ViewBuilder chart: @escaping () -> Chart
	) -> some View {
		Section {
			TransparentNavigationLink(destination: destination) {
				VStack(alignment: .leading) {
					Label(title, systemImage: systemImage)
					
					chart()
						.chartLegend(.hidden)
						.chartXAxis(.hidden)
						.chartYAxis(.hidden)
						.overlay(alignment: .bottom) {
							if showBaseline {
								Color.primary.opacity(0.1).frame(height: 1)
							}
						}
				}
				.padding(.vertical, 8)
			}
		}
	}
	
	private struct FilterPicker<ID: FilterableID>: View {
		var title: String
		var allAllowedLabel: String
		var allowedLabel: (Int) -> String
		var allowAllButton: String
		var allowNoneButton: String
		
		@Binding var excluded: Set<ID>
		
		@Environment(\.assets) private var assets
		
		var body: some View {
			let all = ID.knownIDs(assets: assets)
			let allowed = Set(all).subtracting(excluded)
			NavigationLink {
				List(all, id: \.self) { id in
					listRow(for: id)
				}
				.navigationTitle(title)
				.toolbar {
					ToolbarItemGroup(placement: .bottomBar) {
						Button(allowAllButton) { excluded = [] }
							.disabled(excluded.isEmpty)
						
						Button(allowNoneButton) { excluded = Set(all) }
							.disabled(allowed.isEmpty)
					}
				}
			} label: {
				HStack {
					Text(title)
					Spacer()
					Group {
						if excluded.isEmpty {
							Text(allAllowedLabel)
						} else if let allowed = allowed.onlyElement() {
							allowed.label
						} else {
							Text(allowedLabel(allowed.count))
						}
					}
					.foregroundStyle(.secondary)
				}
			}
		}
		
		func listRow(for id: ID) -> some View {
			Button {
				excluded.formSymmetricDifference([id])
			} label: {
				HStack {
					let isAllowed = !excluded.contains(id)
					
					id.icon
						.saturation(isAllowed ? 1 : 0)
						.frame(height: 40)
					
					id.label
						.tint(.primary)
						.opacity(isAllowed ? 1 : 0.5)
					
					Spacer()
					
					Image(systemName: "checkmark")
						.opacity(isAllowed ? 1 : 0)
				}
			}
		}
	}
}

extension QueueID: DefaultsValueConvertible {}

extension Agent.ID: FilterableID {
	static func knownIDs(assets: AssetCollection?) -> [Self] {
		assets?.agents.sorted(on: \.value.displayName).map(\.key) ?? []
	}
	
	var icon: some View {
		AgentImage.icon(self)
	}
	
	var label: some View {
		AgentLabel(agent: self)
	}
}

#if DEBUG
@available(iOS 16.0, *)
struct StatisticsView_Previews: PreviewProvider {
	static var previews: some View {
		StatisticsView(
			user: PreviewData.user, matchList: PreviewData.matchList,
			statistics: PreviewData.statistics
		)
		.withToolbar()
	}
}
#endif
