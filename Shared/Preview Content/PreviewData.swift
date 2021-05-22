import Foundation
import ValorantAPI

enum PreviewData {
	static let playerID = Player.ID(.init(uuidString: "3FA8598D-066E-5BDB-998C-74C015C5DBA5")!)
	static let user = UserInfo(
		account: .init(
			gameName: "Julian", tagLine: "665",
			createdAt: Date().addingTimeInterval(-4000)
		),
		id: playerID
	)
	
	static let singleMatch = try! loadJSON(named: "example_match", as: MatchDetails.self)
	
	static let compUpdates = try! loadJSON(named: "example_updates", as: [CompetitiveUpdate].self)
	
	static let matchList = MatchList(
		user: user,
		chronology: .init(entries: compUpdates)
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
