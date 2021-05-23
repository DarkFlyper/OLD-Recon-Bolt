import Foundation
import ValorantAPI
import ArrayBuilder

extension AssetClient {
	func getAgentInfo() -> BasicPublisher<[AgentInfo]> {
		send(AgentInfoRequest())
			.map { wrapped in
				assert(wrapped.errors.count == 1)
				return wrapped.decoded
			}
			.eraseToAnyPublisher()
	}
}

private struct AgentInfoRequest: AssetRequest {
	let path = "/v1/agents"
	
	typealias Response = BadDataWorkaround<AgentInfo>
}

// For some reason riot decided to include a borked version of Sova (Hunter_NPE) that's missing some parts.
private struct BadDataWorkaround<Element>: Decodable where Element: Decodable {
	var decoded: [Element] = []
	var errors: [Error] = []
	
	init(from decoder: Decoder) throws {
		var container = try decoder.unkeyedContainer()
		while !container.isAtEnd {
			do {
				decoded.append(try container.decode(Element.self))
			} catch {
				errors.append(error)
				// skip
				_ = try! container.decode(Dummy.self)
			}
		}
	}
	
	private struct Dummy: Decodable {}
}

struct AgentInfo: Codable, Identifiable {
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
	
	@ArrayBuilder<AssetImage>
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
