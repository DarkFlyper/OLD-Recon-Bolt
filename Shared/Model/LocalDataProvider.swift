import SwiftUI
import Combine
import ValorantAPI
import HandyOperators

extension View {
	func withLocalData<Value: LocalDataStored>(
		_ value: LocalData<Value>,
		id: Value.ID,
		animation: Animation? = .default
	) -> some View {
		modifier(LocalDataModifier(value: value.$wrappedValue, id: id, animation: animation))
	}
	
	func withLocalData<Value: LocalDataAutoUpdatable>(
		_ value: LocalData<Value>,
		id: Value.ID,
		shouldAutoUpdate: Bool = false,
		animation: Animation? = .default
	) -> some View {
		modifier(LocalDataModifier(
			value: value.$wrappedValue,
			id: id,
			animation: animation,
			autoUpdate: shouldAutoUpdate ? Value.autoUpdate(for:using:) : nil
		))
	}
	
	func lockingLocalData() -> some View {
		self.environment(\.isLocalDataLocked, true)
	}
}

extension EnvironmentValues {
	var isLocalDataLocked: Bool {
		get { self[Key.self] }
		set { self[Key.self] = newValue }
	}
	
	private enum Key: EnvironmentKey {
		static let defaultValue = false
	}
}

@propertyWrapper
struct LocalData<Value: LocalDataStored>: DynamicProperty {
	@State fileprivate(set) var wrappedValue: Value?
	
	var projectedValue: Self { self }
	
	init(wrappedValue: Value?) {
		self._wrappedValue = .init(initialValue: wrappedValue)
	}
}

private struct LocalDataModifier<Value: LocalDataStored>: ViewModifier {
	@Binding var value: Value?
	var id: Value.ID
	var animation: Animation?
	var autoUpdate: ((Value.ID, ValorantClient) async throws -> Void)? = nil
	
	@State private var token: (id: Value.ID, AnyCancellable)? = nil
	@Environment(\.isLocalDataLocked) var isLocalDataLocked
	
	func body(content: Content) -> some View {
		content
			.task(id: id) {
				guard !isLocalDataLocked else { return }
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
			.valorantLoadTask(id: id) {
				guard !isLocalDataLocked else { return }
				try await autoUpdate?(id, $0)
			}
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
	
	private init() {}
	
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

extension LocalDataManager where Object == MatchDetails {
	func unloadedMatches(in matchList: MatchList, maxCount: Int) -> [Match.ID] {
		matchList.matches
			.map(\.id)
			.prefix(maxCount)
			.prefix { cachedObject(for: $0) == nil }
	}
}

extension ValorantClient {
	func autoUpdateMatchList(for userID: User.ID) async throws {
		let manager = LocalDataProvider.shared.matchListManager
		try await manager.autoUpdateObject(for: userID) { existing in
			let list = existing ?? MatchList(userID: userID)
			return try await list <- loadMatches <- autoFetchMatchListDetails
		}
	}
	
	func autoFetchMatchListDetails(for matchList: MatchList) {
		Task.detached { [self] in
			let manager = LocalDataProvider.shared.matchDetailsManager
			let maxAutoFetchedMatches = 10
			let unloadedMatches = await manager.unloadedMatches(
				in: matchList,
				maxCount: maxAutoFetchedMatches + 1 // we don't need more than our maximum except to know that it's been exceeded
			)
			guard let newestMatch = unloadedMatches.first else { return }
			
			if unloadedMatches.count > maxAutoFetchedMatches {
				// too many unloaded matches—just fetch the most recent one
				try? await fetchMatchDetails(for: newestMatch)
			} else {
				// the last loaded match is close enough to catch up with reasonably few requests—let's do it!
				try? await fetchMatchDetails(for: unloadedMatches)
			}
		}
	}
	
	func updateMatchList(for userID: User.ID, update: @escaping (inout MatchList) async throws -> Void) async throws {
		let manager = LocalDataProvider.shared.matchListManager
		guard let matchList = await manager.cachedObject(for: userID) else { return }
		LocalDataProvider.shared.store(try await matchList <- update <- autoFetchMatchListDetails)
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
	
	func fetchMatchDetails(for matchIDs: [Match.ID]) async throws {
		try await withThrowingTaskGroup(of: Void.self) { group in
			for matchID in matchIDs {
				group.addTask {
					try await self.fetchMatchDetails(for: matchID)
				}
			}
			for try await _ in group {} // TODO: might be able to remove this once the function stops being rethrows
		}
	}
}
