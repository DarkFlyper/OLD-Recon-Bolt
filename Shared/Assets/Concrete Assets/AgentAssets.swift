import Foundation
import ValorantAPI
import Protoquest

extension AssetClient {
	func getAgentInfo() async throws -> [AgentInfo] {
		try await send(AgentInfoRequest())
	}
}

private struct AgentInfoRequest: AssetRequest {
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
	var bustPortrait: AssetImage
	var fullPortrait: AssetImage
	var killfeedPortrait: AssetImage
	var isFullPortraitRightFacing: Bool
	var assetPath: String
	
	var images: [AssetImage] {
		displayIcon
		bustPortrait
		fullPortrait
		killfeedPortrait
		role.displayIcon
		abilities.compactMap(\.displayIcon)
	}
	
	private static let indexRemappings: [Int: Int] = [0: 2, 1: 0, 2: 1]
	/// abilities are given in the wrong order; this reorders them appropriately
	func ability(_ index: Int) -> AgentInfo.Ability {
		abilities[Self.indexRemappings[index] ?? index]
	}
	
	struct Role: Codable {
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
		var slot: String
		var displayIcon: AssetImage?
	}
}
