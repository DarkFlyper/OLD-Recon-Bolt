import Foundation
import Combine
import UserDefault

protocol MatchList: ObservableObject {
	var userID: UUID { get }
	var matches: [Match] { get }
	var minMissedMatches: Int { get }
	
	func switchUser(to id: UUID)
	func loadOlderMatches(using client: Client) -> AnyPublisher<Bool, Error>
	func loadNewerMatches(using client: Client) -> AnyPublisher<Bool, Error>
}

final class PreviewMatchList: MatchList {
	let userID = UUID()
	let matches: [Match]
	let minMissedMatches = 3
	
	init(matches: [Match]) {
		self.matches = matches
	}
	
	func switchUser(to id: UUID) { fatalError() }
	func loadOlderMatches(using client: Client) -> AnyPublisher<Bool, Error> { fatalError() }
	func loadNewerMatches(using client: Client) -> AnyPublisher<Bool, Error> { fatalError() }
}

final class FetchingMatchList: MatchList {
	@UserDefault("storedMatchList") private static var stored: Storage?
	static let requestSize = 20
	
	@Published private(set) var userID = UUID() // bogus id for "uninitialized" state (StateObjects can't be optional)
	@Published private(set) var matches: [Match] = [] {
		didSet { save() }
	}
	@Published private(set) var minMissedMatches = 0 {
		didSet { assert(minMissedMatches >= 0) }
	}
	
	func switchUser(to id: UUID) {
		guard id != userID else { return } // already switched to this user
		userID = id
		if let stored = Self.stored, stored.userID == userID {
			matches = stored.matches
			minMissedMatches = stored.minMissedMatches
		} else {
			matches = []
			minMissedMatches = 0
		}
	}
	
	func loadOlderMatches(using client: Client) -> AnyPublisher<Bool, Error> {
		let startIndex = min(80, matches.count + minMissedMatches)
		return client
			.getCompetitiveUpdates(userID: userID, startIndex: startIndex)
			.receive(on: DispatchQueue.main)
			.map { self.addMatches($0, startIndex: startIndex) }
			.eraseToAnyPublisher()
	}
	
	func loadNewerMatches(using client: Client) -> AnyPublisher<Bool, Error> {
		let startIndex = max(0, minMissedMatches - Self.requestSize + 1) // 1 overlap to check contiguity
		return client
			.getCompetitiveUpdates(userID: userID, startIndex: startIndex)
			.receive(on: DispatchQueue.main)
			.map { self.addMatches($0, startIndex: startIndex) }
			.eraseToAnyPublisher()
	}
	
	/// - returns: whethere anything changed (new matches added or minMissedMatches updated)
	private func addMatches(_ new: [Match], startIndex sentStartIndex: Int) -> Bool {
		guard !new.isEmpty else {
			print("no matches passed to addMatches!")
			return false
		}
		guard !matches.isEmpty else {
			matches = new
			return true
		}
		
		let firstNew = new.first!
		let lastNew = new.last!
		
		// oof
		if let overlapStart = matches.firstIndexByID(of: firstNew) {
			let expectedOverlapStart = sentStartIndex - minMissedMatches
			let oldMin = minMissedMatches
			minMissedMatches += max(0, expectedOverlapStart - overlapStart)
			
			if let lastIndex = new.firstIndexByID(of: matches.last!) {
				let nonOverlapping = new.suffix(from: lastIndex + 1)
				guard !nonOverlapping.isEmpty || minMissedMatches != oldMin else { return false }
				matches.append(contentsOf: nonOverlapping)
			} else {
				return false
			}
		} else if let overlapEnd = matches.firstIndexByID(of: lastNew) {
			let overlap = matches.prefix(through: overlapEnd).count
			let nonOverlapping = new.dropLast(overlap)
			guard !nonOverlapping.isEmpty || minMissedMatches != sentStartIndex else { return false }
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
		return true
	}
	
	func save() {
		Self.stored = Storage(
			userID: userID,
			matches: matches,
			minMissedMatches: minMissedMatches
		)
	}
	
	struct Storage: Codable, DefaultsValueConvertible {
		var userID: UUID
		var matches: [Match]
		var minMissedMatches: Int
	}
}

extension Array where Element: Identifiable {
	func firstIndexByID(of element: Element) -> Index? {
		let id = element.id
		return firstIndex { $0.id == id }
	}
}
