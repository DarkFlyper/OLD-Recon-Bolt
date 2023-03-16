import Foundation
import ValorantAPI

final class Statistics {
	// for icons
	let modeByQueue: [QueueID?: GameMode.ID]
	
	let playtime: Playtime
	let hitDistribution: HitDistribution
	
	init(userID: User.ID, matches: [MatchDetails]) {
		modeByQueue = .init(
			matches.map { ($0.matchInfo.queueID, $0.matchInfo.modeID) },
			uniquingKeysWith: { old, new in old }
		)
		
		playtime = .init(userID: userID, matches: matches)
		hitDistribution = .init(userID: userID, matches: matches)
	}
	
	struct Playtime {
		var total: TimeInterval = 0
		var byQueue: [QueueID?: TimeInterval] = [:]
		var byPremade: [User.ID: TimeInterval] = [:]
		
		init(userID: User.ID, matches: [MatchDetails]) {
			for match in matches {
				let queue = match.matchInfo.queueID
				let gameLength = match.matchInfo.gameLength
				total += gameLength
				byQueue[queue, default: 0] += gameLength
				
				let user = match.players.firstElement(withID: userID)!
				for player in match.players {
					guard player.partyID == user.partyID, player.id != userID else { continue }
					byPremade[player.id, default: 0] += gameLength
				}
			}
		}
	}
	
	struct HitDistribution {
		var overall = Tally()
		var byWeapon: [Weapon.ID: Tally] = [:]
		
		init(userID: User.ID, matches: [MatchDetails]) {
			let rounds = matches
				.lazy
				.flatMap(\.roundResults)
				.map { $0.stats(for: userID)! }
			for round in rounds {
				guard let weapon = round.economy.weapon else { continue }
				// TODO: improve on this horrible naive heuristic lol
				for damage in round.damageDealt {
					overall += damage
					byWeapon[weapon, default: .zero] += damage
				}
			}
		}
		
		struct Tally {
			public var headshots = 0
			public var bodyshots = 0
			public var legshots = 0
			
			var total: Int { headshots + bodyshots + legshots }
			
			static let zero = Self()
			
			static func += (lhs: inout Self, rhs: RoundResult.PlayerStats.Damage) {
				lhs.headshots += rhs.headshots
				lhs.bodyshots += rhs.bodyshots
				lhs.legshots += rhs.legshots
			}
		}
	}
}

extension RoundResult {
	func stats(for userID: User.ID) -> PlayerStats? {
		playerStats.onlyElement { $0.subject == userID }
	}
}

#if DEBUG
extension PreviewData {
	static let statistics = Statistics(userID: userID, matches: allMatches)
	
	static let allMatches: [MatchDetails] = Array(exampleMatches.values)
	+ [singleMatch, strangeMatch, surrenderedMatch, funkySpikeRush, deathmatch, escalation]
}
#endif
