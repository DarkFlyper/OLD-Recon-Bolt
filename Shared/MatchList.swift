import Foundation
import Combine
import UserDefault
import HandyOperators

struct MatchList: Codable, DefaultsValueConvertible {
	let user: UserInfo
	private(set) var matches: [Match] = []
	private(set) var minMissedMatches = 0 {
		didSet { assert(minMissedMatches >= 0) }
	}
	
	/// - throws: if nothing changed (no new matches added and minMissedMatches unchanged)
	func addingMatches(_ new: [Match], startIndex sentStartIndex: Int) throws -> Self {
		let new = self <- { $0.tryToAddMatches(new, startIndex: sentStartIndex) }
		
		guard false
				|| new.minMissedMatches != minMissedMatches
				|| new.matches.count != matches.count
		else { throw NoNewMatchesError() }
		
		return new
	}
	
	private mutating func tryToAddMatches(_ new: [Match], startIndex sentStartIndex: Int) {
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
			let expectedOverlapStart = sentStartIndex - minMissedMatches
			minMissedMatches += max(0, expectedOverlapStart - overlapStart)
			
			guard let lastIndex = new.firstIndexByID(of: matches.last!) else { return }
			let nonOverlapping = new.suffix(from: lastIndex + 1)
			guard !nonOverlapping.isEmpty else { return }
			
			matches.append(contentsOf: nonOverlapping)
		} else if let overlapEnd = matches.firstIndexByID(of: lastNew) {
			let overlap = matches.prefix(through: overlapEnd).count
			let nonOverlapping = new.dropLast(overlap)
			guard !nonOverlapping.isEmpty else { return }
			
			matches = nonOverlapping + matches
			minMissedMatches = sentStartIndex
		} else {
			// no overlap!
			if matches.last!.startTime > firstNew.startTime {
				assert(sentStartIndex == matches.count + minMissedMatches)
				// first older match is right before our current oldest
				matches.append(contentsOf: new)
			} else if matches.first!.startTime < lastNew.startTime {
				// TODO: figure out how to handle this; easiest would be to just keep refreshing until we reach our newest existing match
				print("non-contiguous match history: too many matches played since last refresh!")
				minMissedMatches += new.count
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
			startIndex: min(80, list.matches.count + list.minMissedMatches) // API seems to fail for startIndex > 80
		)
	}
	
	func loadNewerMatches(for list: MatchList) -> AnyPublisher<MatchList, Error> {
		loadMatches(
			for: list,
			startIndex: max(0, list.minMissedMatches - Self.requestSize + 1) // 1 overlap to check contiguity
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
