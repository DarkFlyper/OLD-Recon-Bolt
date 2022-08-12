import SwiftUI
import ValorantAPI

struct MatchListFilter: Codable {
	var queues = AllowList<QueueID>()
	var maps = AllowList<MapID>()
	var shouldShowUnfetched = true
	
	var isActive: Bool {
		maps.isEnabled || queues.isEnabled || !shouldShowUnfetched
	}
	
	func accepts(_ update: CompetitiveUpdate, details: MatchDetails?) -> Bool {
		guard isActive else { return true }
		guard maps.allows(update.mapID) else { return false }
		guard let details else {
			return shouldShowUnfetched || queues.allows(.competitive) && update.isRanked
		}
		return details.matchInfo.queueID.map(queues.allows) ?? false
	}
	
	struct AllowList<ID: FilterableID>: Codable {
		var isEnabled = false
		var allowed: Set<ID> = []
		
		func allows(_ id: ID) -> Bool {
			!isEnabled || allowed.contains(id)
		}
		
		mutating func toggle(_ id: ID) {
			allowed.formSymmetricDifference([id])
		}
	}
}

protocol FilterableID: Hashable, Codable {
	associatedtype Label: View
	
	static var knownIDs: [Self] { get }
	
	var label: Label { get }
}

extension QueueID: FilterableID {
	static var knownIDs: [Self] { knownQueues }
	
	var label: some View {
		Text(name)
	}
}

extension MapID: FilterableID {
	static var knownIDs: [Self] { knownStandardMaps }
	
	var label: some View {
		MapImage.LabelText(mapID: self)
	}
}
