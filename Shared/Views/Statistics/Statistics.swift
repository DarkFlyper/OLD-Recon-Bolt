import Foundation
import ValorantAPI
import HandyOperators

final class Statistics {
	// for icons
	let modeByQueue: [QueueID?: GameMode.ID]
	
	let userID: User.ID
	let matches: [MatchDetails]
	let playtime: Playtime
	let hitDistribution: HitDistribution
	let winRate: WinRate
	
	init(userID: User.ID, matches: [MatchDetails]) {
		self.userID = userID
		self.matches = matches
		
		modeByQueue = .init(
			matches.map { ($0.matchInfo.queueID, $0.matchInfo.modeID) },
			uniquingKeysWith: { old, new in old }
		)
		
		playtime = .init(userID: userID, matches: matches)
		hitDistribution = .init(userID: userID, matches: matches)
		winRate = .init(userID: userID, matches: matches)
	}
	
	struct Playtime {
		var total: Entry = .init()
		var byQueue: [QueueID?: Entry] = [:]
		var byPremade: [User.ID: Entry] = [:]
		var byNonPremade: [User.ID: Entry] = [:]
		var byMap: [MapID: Entry] = [:]
		
		init(userID: User.ID, matches: [MatchDetails]) {
			for match in matches {
				let queue = match.matchInfo.queueID
				total += match
				byQueue[queue, default: .init()] += match
				byMap[match.matchInfo.mapID, default: .init()] += match
				
				let user = match.players.firstElement(withID: userID)!
				for player in match.players {
					guard player.id != userID else { continue }
					if player.partyID == user.partyID {
						byPremade[player.id, default: .init()] += match
					} else {
						byNonPremade[player.id, default: .init()] += match
					}
				}
			}
			byNonPremade = byNonPremade.filter { $0.value.games.count > 1 }
		}
		
		struct Entry {
			var time: TimeInterval = 0
			var games: [CompetitiveUpdate] = [] // need these to display as match list
			
			static func += (entry: inout Self, match: MatchDetails) {
				entry.games.append(.init(
					id: match.id,
					mapID: match.matchInfo.mapID,
					startTime: match.matchInfo.gameStart
				))
				entry.time += match.matchInfo.gameLength
			}
			
			static func + (lhs: Self, rhs: Self) -> Self {
				.init(time: lhs.time + rhs.time, games: lhs.games + rhs.games)
			}
		}
	}
	
	struct HitDistribution {
		var overall = Tally()
		var byWeapon: [Weapon.ID: Tally] = [:]
		var byMatch: [(time: Date, tally: Tally)]
		
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
				.map { (
					$0.matchInfo.gameStart,
					$0.roundResults.lazy
						.map { $0.stats(for: userID)! }
						.flatMap(\.damageDealt)
						.reduce(into: Tally.zero, +=) as Tally
				) }
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
	
	struct WinRate {
		var byDay: [Date: Tally] = [:]
		var byMap: [MapID: Tally] = [:]
		var byStartingSide: [Side: [MapID: Tally]] = [:]
		var roundsBySide: [MapID: [Side: Tally]] = [:]
		var roundsByLoadoutDelta: [Int: Tally] = [:]
		
		init(userID: User.ID, matches: [MatchDetails]) {
			for match in matches {
				let teamID = match.players.firstElement(withID: userID)!.teamID
				let winner = match.teams.first(where: \.won)
				let outcome: Outcome = winner == nil ? .draw
				: winner?.id == teamID ? .win : .loss
				
				let day = Calendar.current.startOfDay(for: match.matchInfo.gameStart)
				byDay[day, default: .zero] += outcome
				
				let map = match.matchInfo.mapID
				byMap[map, default: .zero] += outcome
				
				if let startingSide = Side(teamID), let structure = match.roundStructure {
					let playerTeams = Dictionary(uniqueKeysWithValues: match.players.lazy.map { ($0.id, $0.teamID) })
					
					byStartingSide[startingSide, default: [:]][map, default: .zero] += outcome
					for round in match.roundResults {
						guard round.outcome != .surrendered else { break }
						let side = startingSide.flipped(if: structure.areRolesSwapped(inRound: round.number))
						let outcome: Outcome = round.winningTeam == teamID ? .win : .loss
						roundsBySide[map, default: [:]][side, default: .zero] += outcome
						
						let averageLoadoutValues: [Team.ID: Int] = [Team.ID: [RoundResult.PlayerStats]](
							grouping: round.playerStats,
							by: { playerTeams[$0.subject]! }
						)
						.mapValues { $0.lazy.map(\.economy.loadoutValue).reduce(0, +) / $0.count }
						let enemyLoadout = averageLoadoutValues.onlyElement { $0.key != teamID }!.value
						let loadoutDelta = averageLoadoutValues[teamID]! - enemyLoadout
						roundsByLoadoutDelta[loadoutDelta, default: .zero] += outcome
					}
				}
			}
		}
		
		enum Outcome {
			case win, draw, loss
		}
		
		struct Tally: Equatable {
			var wins = 0
			var draws = 0
			var losses = 0
			
			var total: Int { wins + draws + losses }
			
			static let zero = Self()
			
			static func + (lhs: Self, rhs: Self) -> Self {
				lhs <- { $0 += rhs }
			}
			
			static func += (lhs: inout Self, rhs: Self) {
				lhs.wins += rhs.wins
				lhs.draws += rhs.draws
				lhs.losses += rhs.losses
			}
			
			static func += (tally: inout Self, outcome: Outcome) {
				switch outcome {
				case .win:
					tally.wins += 1
				case .draw:
					tally.draws += 1
				case .loss:
					tally.losses += 1
				}
			}
		}
		
		enum Side: Hashable, CaseIterable {
			case attacking
			case defending
			
			func flipped(`if` condition: Bool) -> Self {
				guard condition else { return self }
				switch self {
				case .attacking: return .defending
				case .defending: return .attacking
				}
			}
			
			init?(_ team: Team.ID) {
				switch team {
				case .red:
					self = .attacking
				case .blue:
					self = .defending
				default:
					return nil
				}
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
