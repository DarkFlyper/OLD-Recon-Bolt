import Foundation
import HandyOperators
import ValorantAPI

struct MatchList: Codable, Identifiable {
	let userID: User.ID
	
	var matches: [CompetitiveUpdate] = []
	var highestLoadedIndex = 0
	
	var canLoadOlderMatches: Bool {
		highestLoadedIndex < requestMaxIndex
	}
	
	var id: User.ID { userID }
	
	func prepending(new: [CompetitiveUpdate]) -> Self {
		if let oldestNew = new.last, let newestExisting = matches.first {
			assert(oldestNew.startTime > newestExisting.startTime)
		}
		return self <- { $0.matches = new + $0.matches }
	}
}

extension MatchList: CustomStringConvertible {
	var description: String {
		"MatchList(user: \(userID), matches: \(matches.map(\.id))"
	}
}

private let requestSize = 20
private let requestMaxIndex = 100

extension ValorantClient {
	func loadMatches(for list: inout MatchList) async throws {
		// have to use a set here because the API likes to deliver very old matches discontiguously
		let knownMatchIDs = Set(list.matches.map(\.id))
		// conserve requests on first load
		let maxIndex = list.matches.isEmpty ? requestSize : requestMaxIndex
		
		var foundUpdates: [CompetitiveUpdate] = []
		for startIndex in stride(from: 0, to: maxIndex, by: requestSize) {
			let updates = try await getUpdates(for: list, startIndex: startIndex)
			guard !updates.isEmpty else { break }
			
			let overlapStart = updates.firstIndex { knownMatchIDs.contains($0.id) }
			foundUpdates += updates.prefix(upTo: overlapStart ?? updates.endIndex)
			
			if overlapStart != nil {
				break // no need to proceed past already-known matches
			}
		}
		
		list.highestLoadedIndex += foundUpdates.count
		
		list.matches = foundUpdates + list.matches
	}
	
	func loadOlderMatches(for list: inout MatchList) async throws {
		guard let oldestKnownMatch = list.matches.last else { return }
		
		for startIndex in stride(from: list.matches.count, to: requestMaxIndex, by: requestSize) {
			let updates = try await getUpdates(for: list, startIndex: startIndex)
			guard let oldestNew = updates.last else { break }
			
			// It's technically possible that these matches are all newer than our existing matches.
			guard oldestNew.startTime <= oldestKnownMatch.startTime else { continue }
			
			let overlapEnd = updates.lastIndex(where: { $0.id == oldestKnownMatch.id })
			list.matches += updates.suffix(
				from: overlapEnd.map(updates.index(after:))
					?? updates.startIndex
			)
		}
		
		list.highestLoadedIndex = requestMaxIndex
	}
	
	private func getUpdates(for list: MatchList, startIndex: Int) async throws -> [CompetitiveUpdate] {
		try await getCompetitiveUpdates(
			userID: list.userID,
			startIndex: startIndex,
			endIndex: min(requestMaxIndex, startIndex + requestSize)
		)
	}
}
