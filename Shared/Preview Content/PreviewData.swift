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
	/// A spike rush involving chamber Q/X and neon X.
	static let funkySpikeRush = loadJSON(named: "funky_spike_rush", in: "example matches", as: MatchDetails.self)
	static let deathmatch = loadJSON(named: "deathmatch", in: "example matches", as: MatchDetails.self)
	static let escalation = loadJSON(named: "escalation", in: "example matches", as: MatchDetails.self)
	static let doubleDamage = loadJSON(named: "double_damage", in: "example matches", as: MatchDetails.self)
	
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
	static let strangeSummary = loadJSON(named: "strange_summary", as: CareerSummary.self)
	
	static let contractDetails = loadJSON(named: "example_contracts", as: ContractDetails.self)
	static let dailyTicket = loadJSON(named: "example_daily_ticket", as: DailyTicketProgress.self)
	static let gameConfig = loadJSON(named: "example_config", as: GameConfig.self)
	static let contractsProgress = ContractsProgress(contracts: contractDetails, daily: dailyTicket)
	@MainActor
	static let resolvedContracts = ResolvedContracts(
		progress: contractsProgress,
		assets: AssetManager.forPreviews.assets,
		seasons: AssetManager.forPreviews.assets?.seasons.with(gameConfig)
	)
	
	static let pregameInfo = loadJSON(named: "example_pregame", as: LivePregameInfo.self)
	
	static let liveGameInfo = loadJSON(named: "example_live_game", as: LiveGameInfo.self)
	
	static let singleMatchData = MatchViewData(details: singleMatch, userID: userID)
	static let strangeMatchData = MatchViewData(details: strangeMatch, userID: userID)
	static let surrenderedMatchData = MatchViewData(details: surrenderedMatch, userID: userID)
	static let funkySpikeRushData = MatchViewData(details: funkySpikeRush, userID: userID)
	
	static let roundData = RoundData(round: 0, in: singleMatchData)
	static let midRoundData = roundData <- {
		$0.currentPosition = ($0.events[4].position + $0.events[5].position) / 2
	}
	
	static let inventory = loadJSON(named: "example_inventory", as: Inventory.self)
	static let loadout = loadJSON(named: "example_loadout", as: Loadout.self)
	
	static let party = loadJSON(named: "example_party", as: Party.self)
	
	static let storeOffers = loadJSON(named: "example_store_offers", as: [StoreOffer].self)
	static let storefront = loadJSON(named: "example_storefront", as: Storefront.self)
	static let storeWallet = loadJSON(named: "example_store_wallet", as: StoreWallet.self)
	
	static let matchList = MatchList(
		userID: user.id,
		matches: compUpdates
	)
	
	private static func loadJSON<T>(
		named name: String,
		in subdirectory: String? = nil,
		as type: T.Type = T.self,
		using decoder: JSONDecoder = ValorantClient.responseDecoder
	) -> T where T: Decodable {
		guard let url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: subdirectory) else {
			fatalError("missing file \(name).json")
		}
		do {
			let raw = try Data(contentsOf: url)
			return try decoder.decode(T.self, from: raw)
		} catch {
			fatalError("error decoding \(name).json: \(error)")
		}
	}
}
#endif
