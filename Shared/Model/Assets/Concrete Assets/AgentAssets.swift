import Foundation
import ValorantAPI

extension AssetClient {
	func getAgentInfo() async throws -> [AgentInfo] {
		let wrapped = try await send(AgentInfoRequest())
		assert(wrapped.errors.count == 1)
		return wrapped.decoded
	}
}

private struct AgentInfoRequest: AssetRequest {
	let path = "/v1/agents"
	
	// For some reason riot decided to include a borked version of Sova (Hunter_NPE) that's missing some parts.
	typealias Response = FaultTolerantDecodableArray<AgentInfo>
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
	var isFullPortraitRightFacing: Bool
	var assetPath: String
	
	var images: [AssetImage] {
		displayIcon
		bustPortrait
		fullPortrait
		role.displayIcon
		abilities.compactMap(\.displayIcon)
	}
	
	struct Role: Codable {
		typealias ID = ObjectID<Self, UUID>
		
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
