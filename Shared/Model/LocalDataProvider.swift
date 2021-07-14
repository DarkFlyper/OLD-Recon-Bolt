import SwiftUI
import Combine
import ValorantAPI
import HandyOperators

extension View {
	func withLocalData<Value>(
		_ value: Binding<Value?>,
		animation: Animation? = .default,
		getPublisher: @escaping (LocalDataProvider) -> LocalDataPublisher<Value>
	) -> some View {
		modifier(LocalDataModifier(value: value, animation: animation, getPublisher: getPublisher))
	}
}

private struct LocalDataModifier<Value>: ViewModifier {
	@Binding var value: Value?
	let animation: Animation?
	let getPublisher: (LocalDataProvider) -> LocalDataPublisher<Value>
	
	@State private var token: AnyCancellable? = nil
	
	func body(content: Content) -> some View {
		content.task {
			token = token ?? getPublisher(.shared)
				.receive(on: DispatchQueue.main)
				.sink { newValue, wasCached in
					withAnimation(wasCached ? nil : animation) {
						value = newValue
					}
				}
		}
	}
}

final class LocalDataProvider {
	static let shared = LocalDataProvider()
	
	private init() {
		#if DEBUG
		if isInSwiftUIPreview {
			async { // actually instant because the actors aren't in use
				guard let assets = await AssetManager.forPreviews.assets else { return }
				let currentAct = assets.seasons.currentAct()!
				
				// TODO: use some other mechanism to express this stuff now that it's unified
				await userManager.store(PreviewData.pregameUsers.values, asOf: .now)
				await userManager.store(PreviewData.liveGameUsers.values, asOf: .now)
				dataFetched(PreviewData.pregameInfo)
				dataFetched(PreviewData.liveGameInfo)
				
				await competitiveSummaryManager.store([
					PreviewData.summary,
					// oh no
					PreviewData.summary <- {
						$0.userID = .init("b59a64d7-d396-540b-a448-d0192fe9c785")!
						$0.competitiveInfo!.bySeason![currentAct.id]!.competitiveTier = 17
						$0.competitiveInfo!.bySeason![currentAct.id]!.rankedRating = 69
					},
					PreviewData.summary <- {
						$0.userID = .init("0c55f5a0-60c5-5cad-b591-531803b973b9")!
						$0.competitiveInfo!.bySeason![currentAct.id]!.competitiveTier = 17
						$0.competitiveInfo!.bySeason![currentAct.id]!.rankedRating = 69
					},
				], asOf: .now)
			}
		}
		#endif
	}
	
	// MARK: -
	
	private var matchListManager = LocalDataManager<MatchList>(ageCausingAutoUpdate: .minutes(5))
	
	func matchList(for userID: User.ID) -> LocalDataPublisher<MatchList> {
		matchListManager.objectPublisher(for: userID)
	}
	
	func autoUpdateMatchList(for userID: User.ID, using client: ValorantClient) async throws {
		try await matchListManager.autoUpdateObject(for: userID) { existing in
			let list = existing ?? MatchList(userID: userID)
			return try await list <- client.loadMatches(for:)
		}
	}
	
	func store(_ matchList: MatchList) {
		async { await matchListManager.store(matchList, asOf: .now) }
	}
	
	// MARK: -
	
	private var competitiveSummaryManager = LocalDataManager<CompetitiveSummary>(ageCausingAutoUpdate: .minutes(5))
	
	func competitiveSummary(for userID: User.ID) -> LocalDataPublisher<CompetitiveSummary> {
		competitiveSummaryManager.objectPublisher(for: userID)
	}
	
	func fetchCompetitiveSummary(
		for userID: User.ID,
		using client: ValorantClient,
		forceFetch: Bool = false
	) async throws {
		if forceFetch {
			try await competitiveSummaryManager.store(
				client.getCompetitiveSummary(userID: userID),
				asOf: .now
			)
		} else {
			try await competitiveSummaryManager.fetchIfNecessary(
				for: userID,
				fetch: client.getCompetitiveSummary
			)
		}
	}
	
	// MARK: -
	
	private var userManager = LocalDataManager<User>(ageCausingAutoUpdate: .hours(1))
	
	func user(for id: User.ID) -> LocalDataPublisher<User> {
		userManager.objectPublisher(for: id)
	}
	
	func fetchUsers(for ids: [User.ID], using client: ValorantClient) async throws {
		try await userManager.fetchIfNecessary(ids, fetch: client.getUsers)
	}
	
	// MARK: -
	
	private var matchDetailsManager = LocalDataManager<MatchDetails>()
	
	func matchDetails(for matchID: Match.ID) -> LocalDataPublisher<MatchDetails> {
		matchDetailsManager.objectPublisher(for: matchID)
	}
	
	func fetchMatchDetails(for matchID: Match.ID, using client: ValorantClient) async throws {
		try await matchDetailsManager.fetchIfNecessary(for: matchID) {
			try await client.getMatchDetails(matchID: $0) <- {
				store($0.players.map(\.identity), asOf: $0.matchInfo.gameStart)
			}
		}
	}
	
	// MARK: -
	
	private var playerIdentityManager = LocalDataManager<Player.Identity>()
	
	func identity(for id: Player.ID) -> LocalDataPublisher<Player.Identity> {
		playerIdentityManager.objectPublisher(for: id)
	}
	
	private func store(_ identities: [Player.Identity], asOf updateTime: Date) {
		async { await playerIdentityManager.store(identities, asOf: updateTime) }
	}
	
	// MARK: - updates from other sources
	
	func dataFetched(_ info: LivePregameInfo) {
		store(info.team.players.map(\.identity), asOf: .now)
	}
	
	func dataFetched(_ info: LiveGameInfo) {
		store(info.players.map(\.identity), asOf: .now)
	}
}
