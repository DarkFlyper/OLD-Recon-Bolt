import SwiftUI
import ValorantAPI
import ArrayBuilder

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
			return update.isRanked ? queues.allows(.competitive) : shouldShowUnfetched  
		}
		return details.matchInfo.queueID.map(queues.allows) ?? false
	}
	
	struct AllowList<ID: FilterableID>: Codable {
		var isEnabled = false
		var allowed: Set<ID> = []
		
		func allows(_ id: ID?) -> Bool {
			guard isEnabled else { return true }
			guard let id else { return false }
			return allowed.contains(id)
		}
		
		mutating func toggle(_ id: ID) {
			allowed.formSymmetricDifference([id])
		}
	}
}

protocol FilterableID: Hashable, Codable {
	associatedtype Label: View
	
	static func knownIDs(assets: AssetCollection?) -> [Self]
	
	var label: Label { get }
}

extension QueueID: FilterableID {
	@ArrayBuilder<Self>
	static func knownIDs(assets: AssetCollection?) -> [Self] {
		knownQueues
		let ordered = Set(knownQueues)
		assets?.queues.keys.filter { !ordered.contains($0) }.sorted(on: \.rawValue) ?? []
	}
	
	var label: some View {
		Text(name)
	}
}

extension MapID: FilterableID {
	static func knownIDs(assets: AssetCollection?) -> [Self] {
		guard let assets else { return knownStandardMaps }
		return assets.maps.sorted(on: \.value.displayName).map(\.key)
	}
	
	var label: some View {
		MapImage.LabelText(mapID: self)
	}
}
