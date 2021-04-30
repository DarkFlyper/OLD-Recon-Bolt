import Foundation
import Combine
import UserDefault
import HandyOperators
import ValorantAPI

struct MatchList: Codable, DefaultsValueConvertible {
	let user: UserInfo
	private(set) var matches: [CompetitiveUpdate] = []
	private(set) var estimatedMissedMatches = 0 {
		didSet { assert(estimatedMissedMatches >= 0) }
	}
	
	/// - throws: if nothing changed (no new matches added and minMissedMatches unchanged)
	func addingMatches(_ new: [CompetitiveUpdate], startIndex sentStartIndex: Int) throws -> Self {
		let new = self <- { $0.tryToAddMatches(new, startIndex: sentStartIndex) }
		
		guard false
				|| new.estimatedMissedMatches != estimatedMissedMatches
				|| new.matches.count != matches.count
		else { throw NoNewMatchesError() }
		
		return new
	}
	
	private mutating func tryToAddMatches(_ new: [CompetitiveUpdate], startIndex sentStartIndex: Int) {
		guard !new.isEmpty else {
			print("no matches passed to addMatches!")
			return
		}
		guard !matches.isEmpty else {
			matches = new
			return
		}
		
		let firstNew = new.first!
		let lastNew = new.last!
		
		// oof
		if let overlapStart = matches.firstIndexByID(of: firstNew) {
			let expectedOverlapStart = sentStartIndex - estimatedMissedMatches
			estimatedMissedMatches += max(0, expectedOverlapStart - overlapStart)
			
			guard let lastIndex = new.firstIndexByID(of: matches.last!) else { return }
			let nonOverlapping = new.suffix(from: lastIndex + 1)
			guard !nonOverlapping.isEmpty else { return }
			
			matches.append(contentsOf: nonOverlapping)
		} else if let _ = matches.firstIndexByID(of: lastNew) {
			// sometimes the api seems to decide to discard some older games?? let's work with that
			estimatedMissedMatches = sentStartIndex
			guard let firstKnown = new.firstIndexByID(of: matches.first!) else {
				// all new matches already known
				estimatedMissedMatches = sentStartIndex
				return
			}
			
			let nonOverlapping = new.prefix(upTo: firstKnown)
			guard !nonOverlapping.isEmpty else { return }
			
			matches = nonOverlapping + matches
			estimatedMissedMatches = sentStartIndex
		} else {
			// no overlap!
			if matches.last!.startTime > firstNew.startTime {
				assert(sentStartIndex == matches.count + estimatedMissedMatches)
				// first older match is right before our current oldest
				matches.append(contentsOf: new)
			} else if matches.first!.startTime < lastNew.startTime {
				// TODO: figure out how to handle this; easiest would be to just keep refreshing until we reach our newest existing match
				print("non-contiguous match history: too many matches played since last refresh!")
				estimatedMissedMatches = sentStartIndex + new.count * 3/2
			} else {
				fatalError("unexpected state!")
			}
		}
	}
	
	private struct NoNewMatchesError: LocalizedError {
		let errorDescription: String? = "No further matches received."
	}
}

extension MatchList {
	@UserDefault("storedMatchList") private static var stored: Self?
	
	static func forUser(_ user: UserInfo) -> Self {
		Self.stored
			.filter { $0.user.id == user.id }
			?? .init(user: user)
	}
	
	func save() {
		Self.stored = self
	}
}

extension Client {
	private static let requestSize = 20
	
	func loadOlderMatches(for list: MatchList) -> AnyPublisher<MatchList, Error> {
		loadMatches(
			for: list,
			startIndex: min(80, list.matches.count + list.estimatedMissedMatches) // API seems to fail for startIndex > 80
		)
	}
	
	func loadNewerMatches(for list: MatchList) -> AnyPublisher<MatchList, Error> {
		loadMatches(
			for: list,
			startIndex: max(0, list.estimatedMissedMatches - Self.requestSize + 1) // 1 overlap to check contiguity
		)
	}
	
	private func loadMatches(for list: MatchList, startIndex: Int) -> AnyPublisher<MatchList, Error> {
		getCompetitiveUpdates(userID: list.user.id, startIndex: startIndex)
			.tryMap { try list.addingMatches($0, startIndex: startIndex) }
			.receive(on: DispatchQueue.main)
			.eraseToAnyPublisher()
	}
}

extension Array where Element: Identifiable {
	func firstIndexByID(of element: Element) -> Index? {
		let id = element.id
		return firstIndex { $0.id == id }
	}
}
