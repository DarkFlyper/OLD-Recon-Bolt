import Foundation
import ValorantAPI

extension MapID {
	static func example(index: Int? = nil) -> Self {
		let index = index ?? Self.mapPaths.indices.randomElement()!
		let mapPath = Self.mapPaths[index % Self.mapPaths.count]
		return Self(path: mapPath.path)
	}
}

extension CompetitiveUpdate {
	static func example(tierChange: (Int, Int), tierProgressChange: (Int, Int), index: Int? = nil) -> Self {
		Self(
			id: .init(),
			mapID: .example(index: index),
			startTime: Date().addingTimeInterval(-Double(100 + (index ?? 0) * 50_000 as Int)),
			tierBeforeUpdate: tierChange.0, tierAfterUpdate: tierChange.1,
			tierProgressBeforeUpdate: tierProgressChange.0, tierProgressAfterUpdate: tierProgressChange.1,
			ratingEarned: 0,
			performanceBonus: 0,
			afkPenalty: 0
		)
	}
}
