import Foundation
import ValorantAPI

final class Statistics {
	// for icons
	let modeByQueue: [QueueID?: GameMode.ID]
	
	let matches: [MatchDetails]
	let playtime: Playtime
	let hitDistribution: HitDistribution
	
	init(userID: User.ID, matches: [MatchDetails]) {
		modeByQueue = .init(
			matches.map { ($0.matchInfo.queueID, $0.matchInfo.modeID) },
			uniquingKeysWith: { old, new in old }
		)
		
		self.matches = matches
		
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
		var byMatch: [(id: Match.ID, tally: Tally)]
		
		init(userID: User.ID, matches: [MatchDetails]) {
			let rounds = matches
				.lazy
				.flatMap(\.roundResults)
			for round in rounds {
				let stats = round.stats(for: userID)!
				guard let startingWeapon = stats.economy.weapon else { continue }
				
				for damage in stats.damageDealt {
					overall += damage
				}
				
				// we don't get nearly enough information from the data to say anything with confidence here, so we'll use a heuristic to approximate reality:
				// we know what weapon the user had at the start of the round, and when they get a kill, we know the weapon or ability used
				// so we'll track the last known weapon for the user as the round plays out, and assume all damage dealt to an enemy was done with the last known weapon at their time of death or the end of the round
				var damages: [Player.ID: Tally] = stats.damageDealt.reduce(into: [:]) {
					$0[$1.receiver, default: .zero] += $1
				}
				
				var lastKnownWeapon = startingWeapon
				let allKillsInOrder = round.playerStats
					.lazy
					.flatMap(\.kills)
					.sorted(on: \.roundTimeMillis)
				for kill in allKillsInOrder {
					// update weapon
					if kill.killer == userID {
						lastKnownWeapon = kill.finishingDamage.weapon ?? lastKnownWeapon
					}
					// if we've damaged the victim, assume we used the last weapon we're known to have had at the time they died to do all damage to them
					if let damage = damages.removeValue(forKey: kill.victim) {
						byWeapon[lastKnownWeapon, default: .zero] += damage
					}
				}
				
				// assume last known weapon for all damage without a known kill
				for damage in damages.values {
					byWeapon[lastKnownWeapon, default: .zero] += damage
				}
			}
			
			// this can happen for ability-only damage
			byWeapon = byWeapon.filter { $0.value != .zero }
			
			byMatch = matches
				.lazy
				.map {
					($0.id, $0.roundResults.lazy
						.map { $0.stats(for: userID)! }
						.flatMap(\.damageDealt)
						.reduce(into: .zero, +=))
				}
				.filter { $0.tally != .zero }
		}
		
		struct Tally: Equatable {
			typealias Raw = RoundResult.PlayerStats.Damage
			
			public var headshots = 0
			public var bodyshots = 0
			public var legshots = 0
			
			var total: Int { headshots + bodyshots + legshots }
			
			static let zero = Self()
			
			static func += (lhs: inout Self, rhs: Raw) {
				lhs += .init(rhs)
			}
			
			static func += (lhs: inout Self, rhs: Self) {
				lhs.headshots += rhs.headshots
				lhs.bodyshots += rhs.bodyshots
				lhs.legshots += rhs.legshots
			}
		}
	}
}

extension Statistics.HitDistribution.Tally {
	init(_ damage: Raw) {
		self.init(
			headshots: damage.headshots,
			bodyshots: damage.bodyshots,
			legshots: damage.legshots
		)
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
	+ [singleMatch, strangeMatch, surrenderedMatch, funkySpikeRush, deathmatch, escalation, doubleDamage]
}
#endif
