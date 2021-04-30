import Foundation
import Combine
import UserDefault
import HandyOperators
import ValorantAPI

struct MatchList: Codable, DefaultsValueConvertible {
	@UserDefault("storedMatchList") private static var stored: Self?
	
	let user: UserInfo
	
	var chronology = Chronology<CompetitiveUpdate>()
	
	var matches: [CompetitiveUpdate] { chronology.entries }
	var estimatedMissedMatches: Int { chronology.estimatedMissedEntries }
	
	static func forUser(_ user: UserInfo) -> Self {
		Self.stored
			.filter { $0.user.id == user.id }
			?? .init(user: user)
	}
	
	func save() {
		Self.stored = self
	}
	
	func addingMatches(_ new: [CompetitiveUpdate], startIndex sentStartIndex: Int) throws -> Self {
		try self <- {
			$0.chronology = try $0.chronology
				.addingEntries(new, startIndex: sentStartIndex)
		}
	}
}

extension CompetitiveUpdate: ChronologyEntry {
	var time: Date { startTime }
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
		// TODO: would be much easier to just fetch all 100 we can (if start index only increases we can't miss any even with unfortunate timing)
		getCompetitiveUpdates(userID: list.user.id, startIndex: startIndex)
			.tryMap { try list.addingMatches($0, startIndex: startIndex) }
			.receive(on: DispatchQueue.main)
			.eraseToAnyPublisher()
	}
}
