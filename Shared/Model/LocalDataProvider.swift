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
				// TODO: use some other mechanism to express this stuff now that it's unified
				await userManager.store([] + PreviewData.pregameUsers.values + PreviewData.liveGameUsers.values)
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
		async { await matchListManager.store(matchList) }
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
				store($0.players.map(\.identity))
			}
		}
	}
	
	// MARK: -
	
	private var playerIdentityManager = LocalDataManager<Player.Identity>()
	
	func identity(for id: Player.ID) -> LocalDataPublisher<Player.Identity> {
		playerIdentityManager.objectPublisher(for: id)
	}
	
	func store(_ identities: [Player.Identity]) {
		async { await playerIdentityManager.store(identities) }
	}
}
