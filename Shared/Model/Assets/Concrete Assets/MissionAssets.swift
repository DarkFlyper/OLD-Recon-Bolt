import Foundation
import ValorantAPI

extension AssetClient {
	func getMissionInfo() async throws -> [MissionInfo] {
		try await send(MissionInfoRequest())
	}
}

private struct MissionInfoRequest: AssetRequest {
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
	var activationDate: Date
	var expirationDate: Date
	var tags: [Tag]?
	var progressToComplete: Int
	var objectives: [ObjectiveValue]?
	
	private static let dateValidityCutoff = Date(timeIntervalSince1970: 0)
	var optionalActivationDate: Date? {
		activationDate > Self.dateValidityCutoff ? activationDate : nil
	}
	var optionalExpirationDate: Date? {
		expirationDate > Self.dateValidityCutoff ? expirationDate : nil
	}
	
	struct MissionType: Codable {
		static let weekly = Self("Weekly")
		static let daily = Self("Daily")
		static let tutorial = Self("Tutorial")
		static let newPlayerExperience = Self("NPE")
		
		var rawValue: String
		
		init(_ rawValue: String) {
			self.rawValue = rawValue
		}
		
		private static let prefix = "EAresMissionType::"
		
		init(from decoder: Decoder) throws {
			let container = try decoder.singleValueContainer()
			let raw = try container.decode(String.self)
			rawValue = raw.hasPrefix(Self.prefix)
				? String(raw.dropFirst(Self.prefix.count))
				: raw
		}
		
		func encode(to encoder: Encoder) throws {
			var container = encoder.singleValueContainer()
			try container.encode(rawValue)
		}
	}
	
	struct Tag: Codable {
		static let combat = Self("Combat")
		static let economy = Self("Econ")
		
		var rawValue: String
		
		init(_ rawValue: String) {
			self.rawValue = rawValue
		}
		
		private static let prefix = "EAresMissionTag::"
		
		init(from decoder: Decoder) throws {
			let container = try decoder.singleValueContainer()
			let raw = try container.decode(String.self)
			rawValue = raw.hasPrefix(Self.prefix)
				? String(raw.dropFirst(Self.prefix.count))
				: raw
		}
		
		func encode(to encoder: Encoder) throws {
			var container = encoder.singleValueContainer()
			try container.encode(rawValue)
		}
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
