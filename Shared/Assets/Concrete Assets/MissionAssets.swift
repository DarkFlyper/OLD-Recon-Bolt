import Foundation
import ValorantAPI
import ErgonomicCodable

extension AssetClient {
	func getMissionInfo() async throws -> [MissionInfo] {
		try await send(MissionInfoRequest())
	}
}

private struct MissionInfoRequest: AssetDataRequest {
	let path = "/v1/missions"
	
	typealias Response = [MissionInfo]
}

struct MissionInfo: AssetItem, Codable, Identifiable {
	typealias ID = Mission.ID
	
	private var uuid: ID
	var id: ID { uuid }
	
	var displayName: String?
	var title: String?
	var assetPath: String
	var type: MissionType?
	var xpGrant: Int
	@SpecialOptional(.distantPast)
	var activationDate: Date?
	@SpecialOptional(.distantPast)
	var expirationDate: Date?
	var tags: [Tag]?
	var progressToComplete: Int
	var objectives: [ObjectiveValue]?
	
	func objective(id: Objective.ID?) -> ObjectiveValue? {
		if let id {
			return objectives?.onlyElement { $0.objectiveID == id }
		} else {
			return objectives?.onlyElement()!
		}
	}
	
	struct MissionType: NamespacedID {
		static let weekly = Self("Weekly")
		static let daily = Self("Daily")
		static let tutorial = Self("Tutorial")
		static let newPlayerExperience = Self("NPE")
		
		static let namespace = "EAresMissionType"
		var rawValue: String
	}
	
	struct Tag: NamespacedID {
		static let combat = Self("Combat")
		static let economy = Self("Econ")
		
		static let namespace = "EAresMissionTag"
		var rawValue: String
	}
	
	struct ObjectiveValue: Codable {
		var objectiveID: Objective.ID
		var value: Int
		
		private enum CodingKeys: String, CodingKey {
			case objectiveID = "objectiveUuid"
			case value
		}
	}
}
