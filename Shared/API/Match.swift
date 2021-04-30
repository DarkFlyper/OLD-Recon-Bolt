import Foundation

struct Match: Codable, Identifiable {
	var id: UUID
	var mapPath: String
	var startTime: Date
	var tierBeforeUpdate: Int
	var tierAfterUpdate: Int
	var tierProgressBeforeUpdate: Int
	var tierProgressAfterUpdate: Int
	var ratingEarned: Int
	var performanceBonus: Int
	var afkPenalty: Int
	
	var isRanked: Bool { tierAfterUpdate != 0 }
	
	var eloChange: Int { eloAfterUpdate - eloBeforeUpdate }
	var eloBeforeUpdate: Int { tierBeforeUpdate * 100 + tierProgressBeforeUpdate }
	var eloAfterUpdate: Int { tierAfterUpdate * 100 + tierProgressAfterUpdate }
	
	private static let mapPaths = [
		("Bonsai", "split"),
		("Triad", "haven"),
		("Duality", "bind"),
		("Ascent", "ascent"),
		("Port", "icebox"),
		("Foxtrot", "breeze"),
	]
	.map { key, name in (path: "/Game/Maps/\(key)/\(key)", name: name) }
	
	private static let mapNames = Dictionary(uniqueKeysWithValues: mapPaths)
	
	var mapName: String? {
		Self.mapNames[mapPath]
	}
	
	private enum CodingKeys: String, CodingKey {
		case id = "MatchID"
		case mapPath = "MapID"
		case startTime = "MatchStartTime"
		case tierAfterUpdate = "TierAfterUpdate"
		case tierBeforeUpdate = "TierBeforeUpdate"
		case tierProgressAfterUpdate = "RankedRatingAfterUpdate"
		case tierProgressBeforeUpdate = "RankedRatingBeforeUpdate"
		case ratingEarned = "RankedRatingEarned"
		case performanceBonus = "RankedRatingPerformanceBonus"
		case afkPenalty = "AFKPenalty"
	}
}

extension String {
	func strippingPrefix(_ prefix: String) -> Substring? {
		guard hasPrefix(prefix) else { return nil }
		return self.dropFirst(prefix.count)
	}
}

extension Match {
	static func example(tierChange: (Int, Int), tierProgressChange: (Int, Int), mapIndex: Int? = nil) -> Match {
		let mapIndex = mapIndex ?? Self.mapPaths.indices.randomElement()!
		let mapPath = Self.mapPaths[mapIndex % Self.mapPaths.count].path
		return Match(
			id: UUID(),
			mapPath: mapPath,
			startTime: Date().addingTimeInterval(-Double(100 + mapIndex * 50_000)),
			tierBeforeUpdate: tierChange.0, tierAfterUpdate: tierChange.1,
			tierProgressBeforeUpdate: tierProgressChange.0, tierProgressAfterUpdate: tierProgressChange.1,
			ratingEarned: 0,
			performanceBonus: 0,
			afkPenalty: 0
		)
	}
}
