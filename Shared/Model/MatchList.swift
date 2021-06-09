import Foundation
import UserDefault
import HandyOperators
import ValorantAPI

struct MatchList: Codable, DefaultsValueConvertible {
	let user: User
	
	var matches: [CompetitiveUpdate] = []
	
	func prepending(new: [CompetitiveUpdate]) -> Self {
		if let oldestNew = new.last, let newestExisting = matches.first {
			assert(oldestNew.startTime > newestExisting.startTime)
		}
		return self <- { $0.matches = new + $0.matches }
	}
}

extension ValorantClient {
	private static let requestSize = 20
	private static let maxIndex = 100
	
	func loadMatches(for list: inout MatchList) async throws {
		// TODO: figure out how to cleanly start out loading just one page but still allow loading more if desired, to avoid hitting rate limits so fast.
		
		let newestKnownMatch = list.matches.first?.id
		
		var foundUpdates: [CompetitiveUpdate] = []
		for startIndex in stride(from: 0, to: Self.maxIndex, by: Self.requestSize) {
			do {
				let updates = try await getCompetitiveUpdates(
					userID: list.user.id,
					startIndex: startIndex,
					endIndex: min(Self.maxIndex, startIndex + Self.requestSize)
				)
				
				if let overlapStart = updates.firstIndex(where: { $0.id == newestKnownMatch }) {
					foundUpdates += updates[..<overlapStart]
					break // no need to proceed past already-known matches
				} else {
					foundUpdates += updates
				}
			} catch ValorantClient.APIError.badResponseCode(400, _, let riotError?)
						where riotError.errorCode == "BAD_PARAMETER" {
				break // probably just no matches this far back yet
			}
		}
		
		list.matches = foundUpdates + list.matches
	}
}
