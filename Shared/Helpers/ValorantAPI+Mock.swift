import Foundation
import ValorantAPI

extension MapID {
	static func example(index: Int? = nil) -> Self {
		let index = index ?? knownMaps.indices.randomElement()!
		return knownMaps[index % knownMaps.count]
	}
}

extension CompetitiveUpdate {
	static func example(tierChange: (Int, Int), tierProgressChange: (Int, Int), ratingEarned: Int? = nil, index: Int? = nil) -> Self {
		Self(
			id: .init(),
			mapID: .example(index: index),
			startTime: Date().addingTimeInterval(-Double(100 + (index ?? 0) * 50_000 as Int)),
			tierBeforeUpdate: tierChange.0, tierAfterUpdate: tierChange.1,
			tierProgressBeforeUpdate: tierProgressChange.0, tierProgressAfterUpdate: tierProgressChange.1,
			ratingEarned: ratingEarned ?? (tierChange.1 * 100 + tierProgressChange.1) - (tierChange.0 * 100 + tierProgressChange.0),
			performanceBonus: 0,
			afkPenalty: 0
		)
	}
}
