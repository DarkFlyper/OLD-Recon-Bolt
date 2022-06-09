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
	
	private enum CodingKeys: String, CodingKey {
		case id = "uuid"
		case displayName
		case displayIcon
		case isHiddenIfNotOwned
	}
}
