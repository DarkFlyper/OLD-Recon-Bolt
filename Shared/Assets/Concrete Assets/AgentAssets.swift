import Foundation
import ValorantAPI
import Protoquest

extension AssetClient {
	func getAgentInfo() async throws -> [AgentInfo] {
		try await send(AgentInfoRequest())
	}
}

private struct AgentInfoRequest: AssetDataRequest {
	let path = "/v1/agents"
	
	var urlParams: [URLParameter] {
		// For some reason riot decided to include a borked version of Sova (Hunter_NPE) that's missing some parts.
		// We can filter it out though, thanks to the amazing ValorantAPI.
		("isPlayableCharacter", true)
	}
	
	typealias Response = [AgentInfo]
}

struct AgentInfo: AssetItem, Codable, Identifiable {
	typealias ID = Agent.ID
	
	private var uuid: ID
	var id: ID { uuid } // lazy rename
	var displayName: String
	var developerName: String
	
	var description: String
	var characterTags: [String]?
	var role: Role
	var abilities: [Ability]
	
	var displayIcon: AssetImage
	var fullPortrait: AssetImage
	var killfeedPortrait: AssetImage
	var background: AssetImage
	var isFullPortraitRightFacing: Bool
	var assetPath: String
	var backgroundGradientColors: [HexEncodedColor]
	
	/// abilities are given in the wrong order; this reorders them appropriately
	func ability(_ slot: Ability.Slot) -> Ability? {
		abilities.first { $0.slot == slot }
	}
	/// abilities are given in the wrong order; this reorders them appropriately
	var abilitiesInOrder: [Ability] {
		Ability.Slot.allCases.compactMap(ability)
	}
	
	struct Role: Codable, Hashable {
		typealias ID = ObjectID<Self, LowercaseUUID>
		
		private var uuid: ID
		var id: ID { uuid } // lazy rename
		var displayName: String
		var description: String
		var displayIcon: AssetImage
		var assetPath: String
	}
	
	struct Ability: Codable {
		var displayName: String
		var description: String
		var slot: Slot
		var displayIcon: AssetImage?
		
		enum Slot: String, Codable, CaseIterable {
			case passive = "Passive"
			case grenade = "Grenade"
			case ability1 = "Ability1"
			case ability2 = "Ability2"
			case ultimate = "Ultimate"
		}
	}
}
