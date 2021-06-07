import Foundation
import Combine
import ValorantAPI

enum PreviewData {
	static let userID = Player.ID(.init(uuidString: "3FA8598D-066E-5BDB-998C-74C015C5DBA5")!)
	static let userInfo = UserInfo(
		account: .init(
			gameName: "Julian", tagLine: "665",
			createdAt: Date().addingTimeInterval(-4000)
		),
		id: userID
	)
	static let user = User(userInfo)
	
	static let singleMatch = try! loadJSON(named: "example_match", as: MatchDetails.self)
	/// A match with only a few rounds and very unbalanced kills, to push layouts to their limits.
	static let strangeMatch = try! loadJSON(named: "strange_match", as: MatchDetails.self)
	
	static let compUpdates = try! loadJSON(named: "example_updates", as: [CompetitiveUpdate].self)
	
	static let singleMatchData = MatchViewData(details: singleMatch, userID: userID)
	
	static let matchList = MatchList(
		user: user,
		matches: compUpdates
	)
	
	private static func loadJSON<T>(
		named name: String,
		as type: T.Type = T.self,
		using decoder: JSONDecoder = ValorantClient.responseDecoder
	) throws -> T where T: Decodable {
		let url = Bundle.main.url(forResource: name, withExtension: "json")!
		let raw = try Data(contentsOf: url)
		return try decoder.decode(T.self, from: raw)
	}
}

#if DEBUG
struct MockClientData: ClientData {
	let user = PreviewData.user
	var matchList: MatchList = PreviewData.matchList
	
	var client: ValorantClient {
		fatalError("no client in previews!")
	}
	
	static func authenticated(using credentials: Credentials) -> AnyPublisher<ClientData, Error> { fatalError() }
	func reauthenticated() -> AnyPublisher<ClientData, Error> { fatalError() }
	
	init?(using keychain: Keychain) {}
	func save(using keychain: Keychain) {}
}

struct EmptyClientData: ClientData {
	let user: User
	var matchList: MatchList
	let client: ValorantClient
	
	static func authenticated(using credentials: Credentials) -> AnyPublisher<ClientData, Error> { fatalError() }
	func reauthenticated() -> AnyPublisher<ClientData, Error> { fatalError() }
	
	init?(using keychain: Keychain) { return nil }
	func save(using keychain: Keychain) {}
}
#endif
