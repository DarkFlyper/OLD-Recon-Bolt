import Foundation
import ValorantAPI
import HandyOperators

// somehow this file is included in builds for profiling. let's avoid that.
#if DEBUG
enum PreviewData {
	static let userID = Player.ID("3fa8598d-066e-5bdb-998c-74c015c5dba5")!
	static let user = User(id: userID, gameName: "Julian", tagLine: "665")
	static let userIdentity = pregameInfo.team.players
		.firstElement(withID: userID)!
		.identity
	
	static let singleMatch = loadJSON(named: "example_match", as: MatchDetails.self)
	/// A match with only a few rounds and very unbalanced kills, to push layouts to their limits.
	static let strangeMatch = loadJSON(named: "strange_match", as: MatchDetails.self)
	/// A match that ended in a surrender, possibly yielding unexpected data.
	static let surrenderedMatch = loadJSON(named: "surrendered_match", as: MatchDetails.self)
	
	static let exampleMatches: [MapID: MatchDetails] = [
		.ascent: "ascent",
		.bind: "bind",
		.breeze: "breeze",
		.fracture: "fracture",
		.haven: "haven",
		.icebox: "icebox",
		.split: "split",
	].mapValues { loadJSON(named: $0, in: "example matches") }
	
	static let compUpdates = loadJSON(named: "example_updates", as: [CompetitiveUpdate].self)
	
	static let summary = loadJSON(named: "example_summary", as: CareerSummary.self)
	
	static let contractDetails = loadJSON(named: "example_contracts", as: ContractDetails.self)
	
	static let pregameInfo = loadJSON(named: "example_pregame", as: LivePregameInfo.self)
	
	static let liveGameInfo = loadJSON(named: "example_live_game", as: LiveGameInfo.self)
	
	static let singleMatchData = MatchViewData(details: singleMatch, userID: userID)
	static let strangeMatchData = MatchViewData(details: strangeMatch, userID: userID)
	static let surrenderedMatchData = MatchViewData(details: surrenderedMatch, userID: userID)
	
	static let roundData = RoundData(round: 0, in: singleMatchData)
	static let midRoundData = roundData <- {
		$0.currentPosition = ($0.events[4].position + $0.events[5].position) / 2
	}
	
	static let inventory = Inventory(loadJSON(named: "example_inventory", as: APIInventory.self))
	
	static let matchList = MatchList(
		userID: user.id,
		matches: compUpdates
	)
	
	static let mockDataStore = ClientDataStore(keychain: MockKeychain(), for: MockClientData.self)
	static let emptyDataStore = ClientDataStore(keychain: MockKeychain(), for: EmptyClientData.self)
	
	private static func loadJSON<T>(
		named name: String,
		in subdirectory: String? = nil,
		as type: T.Type = T.self,
		using decoder: JSONDecoder = ValorantClient.responseDecoder
	) -> T where T: Decodable {
		let url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: subdirectory)!
		
		let raw: Data
		do {
			raw = try Data(contentsOf: url)
		} catch {
			dump(error)
			fatalError("could not read json file at \(url)")
		}
		
		do {
			return try decoder.decode(T.self, from: raw)
		} catch {
			dump(error)
			fatalError("could not decode json from file at \(url)")
		}
	}
}

struct MockClientData: ClientData {
	let client = ValorantClient.mocked
	
	static func authenticated(using credentials: Credentials) -> Self { .init() }
	func reauthenticated() -> Self { self }
	
	init() {}
	init?(using keychain: Keychain) {}
	func save(using keychain: Keychain) {}
}

private struct EmptyClientData: ClientData {
	let client: ValorantClient
	
	static func authenticated(using credentials: Credentials) -> Self { fatalError() }
	func reauthenticated() -> Self { fatalError() }
	
	init?(using keychain: Keychain) { return nil }
	func save(using keychain: Keychain) {}
}
#endif
