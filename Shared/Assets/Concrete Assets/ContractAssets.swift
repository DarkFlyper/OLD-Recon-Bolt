import Foundation
import ValorantAPI
import ErgonomicCodable

extension AssetClient {
	func getContractInfo() async throws -> [ContractInfo] {
		try await send(ContractInfoRequest())
	}
}

private struct ContractInfoRequest: AssetDataRequest {
	let path = "/v1/contracts"
	
	typealias Response = [ContractInfo]
}

struct ContractInfo: AssetItem, Codable, Identifiable {
	typealias ID = Contract.ID
	
	private var uuid: ID
	var id: ID { uuid }
	
	var displayName: String
	var displayIcon: AssetImage?
	var content: Content
	
	struct Content: Codable {
		var relationType: RelationType?
		var relationID: String?
		var chapters: [Chapter]
		@SpecialOptional(.negativeOne)
		var premiumVPCost: Int?
		// TODO: premiumRewardScheduleUuid
		
		var agentID: Agent.ID? {
			guard relationType == .agent else { return nil }
			return relationID.flatMap(Agent.ID.init)
		}
		
		var seasonID: Season.ID? {
			guard relationType == .season else { return nil }
			return relationID.flatMap(Season.ID.init)
		}
		
		private enum CodingKeys: String, CodingKey {
			case relationType
			case relationID = "relationUuid"
			case chapters
			case premiumVPCost
		}
	}
	
	struct RelationType: SimpleRawWrapper {
		static let agent = Self("Agent")
		static let event = Self("Event")
		static let season = Self("Season")
		
		public var rawValue: String
		
		public init(_ rawValue: String) {
			self.rawValue = rawValue
		}
	}
	
	struct Chapter: Codable {
		var isEpilogue: Bool
		var levels: [Level]
		var freeRewards: [Reward]?
	}
	
	struct Level: Codable {
		var xp: Int
		var vpCost: Int
		var isPurchasableWithVP: Bool
		var reward: Reward
	}
	
	struct Reward: Codable {
		var type: RewardType
		/// id of the reward whose type we grant
		var id: String
		var amount: Int
		var isHighlighted: Bool
		
		private enum CodingKeys: String, CodingKey {
			case type
			case id = "uuid"
			case amount
			case isHighlighted
		}
	}
	
	struct RewardType: SimpleRawWrapper {
		static let title = Self("Title")
		static let spray = Self("Spray")
		static let playerCard = Self("PlayerCard")
		static let gunBuddy = Self("EquippableCharmLevel")
		static let skin = Self("EquippableSkinLevel")
		static let currency = Self("Currency")
		static let agent = Self("Character")
		
		public var rawValue: String
		
		public init(_ rawValue: String) {
			self.rawValue = rawValue
		}
	}
}

/// Treats numbers equal to -1 as `nil`.
struct NegativeOneOptionalStrategy: SpecialOptionalStrategy {
	public static func isNil(_ value: Int) -> Bool {
		value == -1
	}
}

extension SpecialOptionalStrategy where Self == NegativeOneOptionalStrategy {
	static var negativeOne: Self { .init() }
}
