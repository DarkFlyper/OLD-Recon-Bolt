import SwiftUI
import ValorantAPI
import Combine
import HandyOperators

struct StatisticsViewWrapper: View {
	var user: User
	var matchList: MatchList
	
	@Environment(\.ownsProVersion) private var ownsProVersion
	
	var body: some View {
		if #available(iOS 16.0, *) {
			if ownsProVersion {
				StatisticsView(user: user, matchList: matchList)
			} else {
				GroupBox {
					VStack {
						Text("Statistics not available!")
							.font(.title.weight(.bold))
							.padding(.bottom, 4)
						
						Text("Statistics require \(Text("Recon Bolt Pro").fontWeight(.medium)), a one-time purchase including a variety of features. Want to give them a look?")
							.frame(maxWidth: .infinity, alignment: .leading)
							.padding(.bottom, 12)
						
						// TODO: sales pitch incl. screenshots? blurred view?
						
						Button {
							// TODO: implement
						} label: {
							HStack {
								Text("View Store in Settings")
								Image(systemName: "chevron.right")
							}
						}
						.buttonStyle(.borderedProminent)
						.fontWeight(.medium)
					}
					.padding(8)
				}
				.padding()
			}
		} else {
			VStack {
				Text("Statistics not available!")
				Text("This feature requires iOS 16 or newer.")
			}
		}
	}
}

@available(iOS 16.0, *)
struct StatisticsView: View {
	var user: User
	var matchList: MatchList
	
	private var sublist: ArraySlice<CompetitiveUpdate> {
		matchList.matches.prefix(fetchCount)
	}
	
	@State var statistics: Statistics?
	@State var fetchCount = 100
	@StateObject var fetcher = MatchFetcher()
	
	@Environment(\.assets) private var assets
	@Environment(\.isIncognito) private var isIncognito
	@Environment(\.valorantLoad) private var load
	
	var body: some View {
		Form {
			loadingSection()
			
			if let statistics {
				playtimeSection(for: statistics)
			}
		}
		.navigationTitle("Statistics")
		.onReceive(fetcher.objectWillChange.debounce(for: 0.2, scheduler: DispatchQueue.main)) { _ in
			// compute stats
			statistics = .init(userID: user.id, matches: sublist.compactMap { fetcher.matches[$0.id] })
		}
	}
	
	func loadingSection() -> some View {
		Section {
			VStack(alignment: .leading, spacing: 12) {
				Text("To gather statistics, we first need to load matches to process. Note that large amounts can take a long time when downloading for the first time!")
				
				HStack {
					Stepper("\(fetchCount) matches", value: $fetchCount, in: 1...matchList.matches.count)
					
					Button("All \(matchList.matches.count)") {
						fetchCount = matchList.matches.count
					}
					.buttonStyle(.bordered)
					.disabled(fetchCount == matchList.matches.count)
				}
				.onAppear {
					fetchCount = min(fetchCount, matchList.matches.count)
				}
				
				let oldestTime = sublist.last!.startTime
				Text("Data going back to \(oldestTime, format: .dateTime.year().month().day())")
					.foregroundStyle(.secondary)
					.font(.footnote)
				
				// TODO: use date instead? or at least allow cutting off from the top? button to filter to specific act?
				
				Button("Load Latest \(fetchCount) Matches") {
					fetcher.fetchMatches(withIDs: sublist.lazy.map(\.id), load: load)
				}
				.bold()
				.buttonStyle(.borderedProminent)
				.frame(maxWidth: .infinity)
			}
			.padding(.vertical, 4)
		} header: {
			Text("Load Data")
		} footer: {
			let fetchedCount = sublist.count { fetcher.matches.keys.contains($0.id) }
			Text("\(fetchedCount)/\(fetchCount) loaded (\(fetcher.errors.count) errors)")
		}
	}
	
	@ViewBuilder
	func playtimeSection(for statistics: Statistics) -> some View {
		Section("Playtime") {
			durationRow(duration: statistics.totalPlaytime) {
				Text("Total Playtime")
			}
		}
		
		Section("By Queue") {
			ForEach(statistics.playtimeByQueue.sorted(on: \.value).reversed(), id: \.key) { queue, time in
				durationRow(duration: time) {
					GameModeImage(id: statistics.modeByQueue[queue]!)
						.frame(height: 24)
					Text(name(for: queue))
				}
			}
		}
		
		if !statistics.playtimeByPremade.isEmpty {
			Section("By Premade Teammate") {
				ForEach(statistics.playtimeByPremade.sorted(on: \.value).reversed(), id: \.key) { teammate, time in
					TransparentNavigationLink {
						MatchListView(userID: teammate)
					} label: {
						durationRow(duration: time) {
							UserLabel(userID: teammate)
						}
					}
				}
			}
		}
	}
	
	func name(for queue: QueueID) -> LocalizedStringKey {
		(assets?.queues[queue]?.name).map { "\($0)" } ?? "Unknown Queue"
	}
	
	func durationRow<Label: View>(duration: TimeInterval, @ViewBuilder label: () -> Label) -> some View {
		HStack {
			label()
			Spacer()
			Text(Duration.seconds(duration), format: .units(
				allowed: [.days, .hours, .minutes],
				width: .abbreviated,
				maximumUnitCount: 2
			))
			.foregroundStyle(.secondary)
		}
	}
	
	struct UserLabel: View {
		var userID: User.ID
		
		@LocalData var user: User?
		
		var body: some View {
			HStack(spacing: 4) {
				if let user {
					Text(user.gameName)
						.fontWeight(.semibold)
					
					Text("#\(user.tagLine)")
						.foregroundStyle(.secondary)
				} else {
					Text("Unknown Player")
						.fontWeight(.semibold)
						.foregroundStyle(.secondary)
				}
			}
			.withLocalData($user, id: userID, shouldAutoUpdate: true)
		}
	}
}

final class Statistics {
	private(set) var totalPlaytime: TimeInterval = 0
	private(set) var playtimeByQueue: [QueueID: TimeInterval] = [:]
	private(set) var modeByQueue: [QueueID: GameMode.ID] = [:]
	private(set) var playtimeByPremade: [User.ID: TimeInterval] = [:]
	
	init(userID: User.ID, matches: [MatchDetails]) {
		for match in matches {
			let queue = match.matchInfo.queueID ?? .custom
			let gameLength = match.matchInfo.gameLength
			playtimeByQueue[queue, default: 0] += gameLength
			totalPlaytime += gameLength
			modeByQueue[queue] = match.matchInfo.modeID
			
			let user = match.players.firstElement(withID: userID)!
			for player in match.players {
				guard player.partyID == user.partyID, player.id != userID else { continue }
				playtimeByPremade[player.id, default: 0] += gameLength
			}
		}
	}
}

@MainActor
final class MatchFetcher: ObservableObject {
	@Published var matches: [Match.ID: MatchDetails] = [:]
	@Published var errors: [Error] = []
	private var tokens: [Match.ID: AnyCancellable] = [:]
	
	func fetchMatches(withIDs ids: some Sequence<Match.ID>, load: @escaping ValorantLoadFunction) {
		errors = []
		
		for match in ids {
			guard tokens[match] == nil else { continue }
			tokens[match] = LocalDataProvider.shared.matchDetailsManager
				.objectPublisher(for: match)
				.receive(on: DispatchQueue.main)
				.sink { [weak self] in self?.matches[match] = $0.value }
			
			Task {
				await load { [weak self] in
					do {
						try await MatchDetails.autoUpdate(for: match, using: $0)
					} catch {
						self?.errors.append(error)
					}
				}
			}
		}
	}
}

#if DEBUG
@available(iOS 16.0, *)
struct StatisticsView_Previews: PreviewProvider {
	static var previews: some View {
		StatisticsViewWrapper(user: PreviewData.user, matchList: PreviewData.matchList)
			.withToolbar()
			.previewDisplayName("Container")
		
		StatisticsView(
			user: PreviewData.user, matchList: PreviewData.matchList,
			statistics: .init(userID: PreviewData.userID, matches: PreviewData.allMatches)
		)
		.withToolbar()
	}
}
#endif
