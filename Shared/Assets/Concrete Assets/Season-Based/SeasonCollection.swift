import Foundation
import ValorantAPI
import Algorithms
import HandyOperators

struct SeasonCollection: AssetItem, Codable {
	var episodes: [Episode.ID: Episode]
	var episodesInOrder: [Episode]
	
	var acts: [Act.ID: Act]
	var actsInOrder: [Act]
	
	var competitiveTiers: [CompetitiveTier.Collection.ID: CompetitiveTier.Collection]
	
	private func currentAct(at time: Date) -> Act? {
		// not requiring the time to be greater than the start date avoids possible undefined periods between acts (like the 3 days between closed beta and act 1) and lets us use binary search for quicker searching
		let firstExceedingIndex = actsInOrder
			.partitioningIndex { time < $0.timeSpan.end } // binary search
		return actsInOrder.elementIfValid(at: firstExceedingIndex)
	}
	
	func actBefore(_ current: Act?) -> Act? {
		guard let current else { return nil }
		guard let currentIndex = actsInOrder.firstIndex(withID: current.id) else { return nil }
		return actsInOrder.elementIfValid(at: currentIndex - 1)
	}
	
	func tierCollections(relevantTo range: ClosedRange<Date>) -> [Act.WithTiers] {
		actsInOrder
			.drop { $0.timeSpan.end < range.lowerBound }
			.prefix { $0.timeSpan.start < range.upperBound }
			.map { ($0, competitiveTiers[$0.competitiveTiers]!) }
	}
	
	func tierInfo(number: Int, in actID: Act.ID) -> CompetitiveTier? {
		guard let act = acts[actID] else { return nil }
		return tiers(in: act).tier(number)
	}
	
	func tierInfo(_ snapshot: RankSnapshot) -> CompetitiveTier? {
		tierInfo(number: snapshot.rank, in: snapshot.season)
	}
	
	func tiers(in act: Act) -> CompetitiveTier.Collection {
		competitiveTiers[act.competitiveTiers]!
	}
	
	func with(_ config: GameConfig) -> Accessor {
		.init(collection: self, offset: config.seasonOffset)
	}
	
	func lowestImmortalPlusTier(in actID: Act.ID) -> Int? {
		guard let act = acts[actID] else { return nil }
		return tiers(in: act).lowestImmortalPlusTier()
	}
	
	struct Accessor {
		var collection: SeasonCollection
		var offset: TimeInterval
		
		/// adjusts acts forwards for matching against unadjusted times
		func adjust(_ act: Act) -> Act {
			act <- adjust(_:)
		}
		
		/// adjusts acts forwards for matching against unadjusted times
		func adjust(_ act: inout Act) {
			act.timeSpan.offset(by: offset)
		}
		
		/// adjusts times backwards for matching against unadjusted acts
		private func adjust(_ time: Date?) -> Date {
			(time ?? .now) - offset
		}
		
		func act(_ id: Act.ID?) -> Act? {
			id.flatMap { collection.acts[$0] }.map(adjust(_:))
		}
		
		func tierInfo(number: Int, in actID: Act.ID? = nil) -> CompetitiveTier? {
			tierInfo(number: number, in: actID.flatMap { collection.acts[$0] })
		}
		
		func tierInfo(_ snapshot: RankSnapshot) -> CompetitiveTier? {
			collection.tierInfo(snapshot)
		}
		
		func currentAct(at time: Date? = nil) -> Act? {
			collection.currentAct(at: adjust(time)).map(adjust(_:))
		}
		
		func currentTiers(at time: Date? = nil) -> CompetitiveTier.Collection? {
			currentAct(at: adjust(time)).map(collection.tiers(in:))
		}
		
		func currentTierInfo(number: Int, at time: Date? = nil) -> CompetitiveTier? {
			currentTiers(at: adjust(time))?.tier(number)
		}
		
		func tierInfo(number: Int?, in act: Act? = nil) -> CompetitiveTier? {
			act.flatMap(collection.tiers(in:))?.tier(number)
		}
		
		func tierCollections(relevantTo range: ClosedRange<Date>) -> [Act.WithTiers] {
			collection.tierCollections(relevantTo: adjust(range.lowerBound)...adjust(range.upperBound))
				.map { $0 <- { adjust(&$0.act) } }
		}
	}
}

struct Act: AssetItem, Identifiable, Codable {
	typealias WithTiers = (act: Act, tiers: CompetitiveTier.Collection)
	
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
	
	private static let absoluteRRStartTime = Date(timeIntervalSince1970: 1611014400) // start of ep2 act1, where they merged immortals
	var usesAbsoluteRRForImmortalPlus: Bool {
		timeSpan.start >= Self.absoluteRRStartTime // >= to cover this and future acts, plus it still works if timeSpan was shifted with a season offset since those are positive
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
	
	func merging(_ other: Self) -> Self {
		.init(start: min(start, other.start), end: max(end, other.end))
	}
	
	mutating func offset(by offset: TimeInterval) {
		start += offset
		end += offset
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
