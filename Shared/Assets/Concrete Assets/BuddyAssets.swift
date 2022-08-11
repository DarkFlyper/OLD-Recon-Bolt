import Foundation
import ValorantAPI

extension AssetClient {
	func getBuddyInfo() async throws -> [BuddyInfo] {
		try await send(BuddyInfoRequest())
	}
}

private struct BuddyInfoRequest: AssetRequest {
	let path = "/v1/buddies"
	
	typealias Response = [BuddyInfo]
}

struct BuddyInfo: AssetItem, Codable, Identifiable {
	var id: Weapon.Buddy.ID
	var displayName: String
	var displayIcon: AssetImage
	var isHiddenIfNotOwned: Bool
	var levels: [Level]
	
	private enum CodingKeys: String, CodingKey {
		case id = "uuid"
		case displayName
		case displayIcon
		case isHiddenIfNotOwned
		case levels
	}
	
	struct Level: Codable, Identifiable {
		var id: Weapon.Buddy.Level.ID
		var displayName: String
		// ignoring the rest because they don't seem to be used yet
		
		enum CodingKeys: String, CodingKey {
			case id = "uuid"
			case displayName
		}
	}
}
