import Foundation
import Combine
import UserDefault
import HandyOperators
import ValorantAPI

struct MatchList: Codable, DefaultsValueConvertible {
	let user: UserInfo
	
	var matches: [CompetitiveUpdate] = []
	
	mutating func addMatches(_ new: [CompetitiveUpdate]) throws {
		let overlapStart = matches.firstIndex { $0.id == matches.first?.id } ?? new.endIndex
		guard overlapStart > new.startIndex else { throw NoNewEntriesError() }
		matches = new[..<overlapStart] + matches
	}
	
	private struct NoNewEntriesError: LocalizedError {
		let errorDescription: String? = "No further entries received."
	}
}

extension ValorantClient {
	private static let requestSize = 20
	private static let maxIndex = 100
	
	typealias IndexedPart = (startIndex: Int, updates: [CompetitiveUpdate])
	
	func loadMatches(for list: MatchList) -> AnyPublisher<MatchList, Error> {
		stride(from: 0, to: Self.maxIndex, by: Self.requestSize).publisher
			.flatMap { (startIndex: Int) in
				self.getCompetitiveUpdates(
					userID: list.user.id,
					startIndex: startIndex,
					endIndex: min(Self.maxIndex, startIndex + Self.requestSize)
				)
				.map { (startIndex: startIndex, updates: $0) }
			}
			.collect() // TODO: stop once overlapping
			.map { (parts: [IndexedPart]) -> [CompetitiveUpdate] in
				Array(parts.sorted(on: \.startIndex).map(\.updates).joined())
			}
			.tryMap { new in try list <- { try $0.addMatches(new) } }
			.receive(on: DispatchQueue.main)
			.eraseToAnyPublisher()
	}
}
