import Foundation
import ValorantAPI

struct SeasonCollection: AssetItem, Codable {
	var episodes: [Episode.ID: Episode]
	var episodesInOrder: [Episode]
	
	var acts: [Act.ID: Act]
	var actsInOrder: [Act]
	
	var competitiveTiers: [CompetitiveTier.Collection.ID: CompetitiveTier.Collection]
	
	func currentAct(at time: Date? = nil) -> Act? {
		// not requiring the time to be greater than the start date avoids possible undefined periods between acts (like the 3 days between closed beta and act 1) and lets us use binary search for quicker searching
		let time = time ?? Date()
		let firstExceedingIndex = actsInOrder
			.partitioningIndex { time < $0.timeSpan.end } // binary search
		return actsInOrder.elementIfValid(at: firstExceedingIndex)
	}
	
	func actBefore(_ current: Act?) -> Act? {
		guard let current else { return nil }
		guard let currentIndex = actsInOrder.firstIndex(withID: current.id) else { return nil }
		return actsInOrder.elementIfValid(at: currentIndex - 1)
	}
	
	func currentTiers(at time: Date? = nil) -> CompetitiveTier.Collection? {
		currentAct(at: time).map { competitiveTiers[$0.competitiveTiers]! }
	}
	
	func currentTierInfo(number: Int, at time: Date? = nil) -> CompetitiveTier? {
		currentTiers(at: time)?.tier(number)
	}
	
	func tierInfo(number: Int, in actID: Act.ID? = nil) -> CompetitiveTier? {
		tierInfo(number: number, in: actID.flatMap { acts[$0] })
	}
	
	func tierInfo(_ snapshot: RankSnapshot) -> CompetitiveTier? {
		tierInfo(number: snapshot.rank, in: snapshot.season)
	}
	
	func tierInfo(number: Int, in act: Act? = nil) -> CompetitiveTier? {
		let tiers = act.map { competitiveTiers[$0.competitiveTiers]! }
		return (tiers ?? currentTiers())?.tier(number)
	}
}

struct Act: AssetItem, Identifiable, Codable {
	var id: Season.ID
	var name: String
	var timeSpan: SeasonTimeSpan
	/// - Note: Closed Beta (the first "act") did not have an associated episode.
	var episode: Episode?
	
	var borders: [ActRankBorder]
	var competitiveTiers: CompetitiveTier.Collection.ID
	
	var nameWithEpisode: String {
		if let episode {
			return "\(episode.name) – \(name)"
		} else {
			return name
		}
	}
}

struct Episode: Identifiable, Codable {
	var id: Season.ID
	var name: String
	var timeSpan: SeasonTimeSpan
}

struct SeasonTimeSpan: Codable {
	var start, end: Date
	
	func contains(_ date: Date) -> Bool {
		// inclusive-exclusive avoids overlap between consecutive time spans
		start <= date && date < end
	}
}

struct ActRankBorder: AssetItem, Codable {
	var id: ObjectID<Self, LowercaseUUID>
	
	var level: Int
	var winsRequired: Int
	/// The full triangle used to display your act rank progress in your career tab.
	var fullImage: AssetImage
	/// The icon used to show the top 9 wins in player lists.
	var icon: AssetImage?
	
	private enum CodingKeys: String, CodingKey {
		case id = "uuid"
		case level
		case winsRequired
		case fullImage = "displayIcon"
		case icon = "smallIcon"
	}
}
