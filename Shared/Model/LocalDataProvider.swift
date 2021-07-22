import SwiftUI
import Combine
import ValorantAPI
import HandyOperators

extension View {
	func withLocalData<Value: LocalDataStored>(
		_ value: Binding<Value?>,
		id: Value.ID,
		animation: Animation? = .default
	) -> some View {
		modifier(LocalDataModifier(value: value, id: id, animation: animation))
	}
	
	func withLocalData<Value: LocalDataAutoUpdatable>(
		_ value: Binding<Value?>,
		id: Value.ID,
		shouldAutoUpdate: Bool = false,
		animation: Animation? = .default
	) -> some View {
		modifier(LocalDataModifier(value: value, id: id, animation: animation) { client in
			{ try await Value.autoUpdate(for: $0, using: client) }
		})
	}
}

private struct LocalDataModifier<Value: LocalDataStored>: ViewModifier {
	@Binding var value: Value?
	var id: Value.ID
	var animation: Animation?
	var autoUpdate: ((ValorantClient) -> (Value.ID) async throws -> Void)? = nil
	
	@State private var token: (id: Value.ID, AnyCancellable)? = nil
	
	func body(content: Content) -> some View {
		content
			.task(id: id) {
				if let token = token, token.id == id { return }
				let cancellable = LocalDataProvider.shared[keyPath: Value.managerPath]
					.objectPublisher(for: id)
					.receive(on: DispatchQueue.main)
					.sink { newValue, wasCached in
						withAnimation(wasCached ? nil : animation) {
							value = newValue
						}
					}
				token = (id, cancellable)
			}
			.valorantLoadTask(id: id) { try await autoUpdate?($0)(id) }
	}
}

protocol LocalDataStored: Identifiable, Codable where ID: LosslessStringConvertible {
	static var managerPath: KeyPath<LocalDataProvider, LocalDataManager<Self>> { get }
}

protocol LocalDataAutoUpdatable: LocalDataStored {
	static func autoUpdate(for id: ID, using client: ValorantClient) async throws
}

extension MatchList: LocalDataAutoUpdatable {
	static let managerPath = \LocalDataProvider.matchListManager as KeyPath
	
	static func autoUpdate(for id: ID, using client: ValorantClient) async throws {
		try await client.autoUpdateMatchList(for: id)
	}
}

extension CareerSummary: LocalDataAutoUpdatable {
	static let managerPath = \LocalDataProvider.careerSummaryManager as KeyPath
	
	static func autoUpdate(for id: ID, using client: ValorantClient) async throws {
		try await client.fetchCareerSummary(for: id)
	}
}

extension User: LocalDataAutoUpdatable {
	static let managerPath = \LocalDataProvider.userManager as KeyPath
	
	static func autoUpdate(for id: ID, using client: ValorantClient) async throws {
		try await client.fetchUsers(for: [id])
	}
}

extension MatchDetails: LocalDataAutoUpdatable {
	static let managerPath = \LocalDataProvider.matchDetailsManager as KeyPath
	
	static func autoUpdate(for id: ID, using client: ValorantClient) async throws {
		try await client.fetchMatchDetails(for: id)
	}
}

extension Player.Identity: LocalDataStored {
	static let managerPath = \LocalDataProvider.playerIdentityManager as KeyPath
}

final class LocalDataProvider {
	fileprivate static let shared = LocalDataProvider()
	
	var matchListManager = LocalDataManager<MatchList>(ageCausingAutoUpdate: .minutes(5))
	var careerSummaryManager = LocalDataManager<CareerSummary>(ageCausingAutoUpdate: .minutes(5))
	var userManager = LocalDataManager<User>(ageCausingAutoUpdate: .hours(1))
	var matchDetailsManager = LocalDataManager<MatchDetails>()
	var playerIdentityManager = LocalDataManager<Player.Identity>()
	
	private init() {
		#if DEBUG
		if isInSwiftUIPreview {
			Task { // actually instant because the actors aren't in use
				guard let assets = await AssetManager.forPreviews.assets else { return }
				let currentAct = assets.seasons.currentAct()!
				
				// TODO: use some other mechanism to express this stuff now that it's unified
				await userManager.store(PreviewData.pregameUsers.values, asOf: .now)
				await userManager.store(PreviewData.liveGameUsers.values, asOf: .now)
				Self.dataFetched(PreviewData.pregameInfo)
				Self.dataFetched(PreviewData.liveGameInfo)
				
				await careerSummaryManager.store([
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
	
	func store(_ matchList: MatchList) {
		Task { await matchListManager.store(matchList, asOf: .now) }
	}
	
	func store(_ identities: [Player.Identity], asOf updateTime: Date) {
		Task { await playerIdentityManager.store(identities, asOf: updateTime) }
	}
	
	// MARK: - updates from other sources
	
	// TODO: still not super happy with these tbh
	static func dataFetched(_ details: MatchDetails) {
		shared.store(details.players.map(\.identity), asOf: details.matchInfo.gameStart)
	}
	
	static func dataFetched(_ info: LivePregameInfo) {
		shared.store(info.team.players.map(\.identity), asOf: .now)
	}
	
	static func dataFetched(_ info: LiveGameInfo) {
		shared.store(info.players.map(\.identity), asOf: .now)
	}
	
	static func dataFetched(_ user: User) {
		Task { await shared.userManager.store(user, asOf: .now) }
	}
}

extension ValorantClient {
	func autoUpdateMatchList(for userID: User.ID) async throws {
		let manager = LocalDataProvider.shared.matchListManager
		try await manager.autoUpdateObject(for: userID) { existing in
			let list = existing ?? MatchList(userID: userID)
			return try await list <- loadMatches(for:)
		}
	}
	
	func updateMatchList(for userID: User.ID, update: @escaping (inout MatchList) async throws -> Void) async throws {
		let manager = LocalDataProvider.shared.matchListManager
		guard let matchList = await manager.cachedObject(for: userID) else { return }
		LocalDataProvider.shared.store(try await matchList <- update)
	}
	
	func fetchCareerSummary(for userID: User.ID, forceFetch: Bool = false) async throws {
		let manager = LocalDataProvider.shared.careerSummaryManager
		if forceFetch {
			try await manager.store(getCareerSummary(userID: userID), asOf: .now)
		} else {
			try await manager.fetchIfNecessary(for: userID, fetch: getCareerSummary)
		}
	}
	
	func fetchUsers(for ids: [User.ID]) async throws {
		let manager = LocalDataProvider.shared.userManager
		try await manager.fetchIfNecessary(ids, fetch: getUsers)
	}
	
	func fetchMatchDetails(for matchID: Match.ID) async throws {
		let manager = LocalDataProvider.shared.matchDetailsManager
		try await manager.fetchIfNecessary(for: matchID) {
			try await getMatchDetails(matchID: $0)
				<- LocalDataProvider.dataFetched
		}
	}
}
