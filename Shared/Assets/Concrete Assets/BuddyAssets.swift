import Foundation
import ValorantAPI

extension AssetClient {
	func getBuddyInfo() async throws -> [BuddyInfo] {
		try await send(BuddyInfoRequest())
	}
}

private struct BuddyInfoRequest: AssetDataRequest {
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
		// ignoring the rest because they don't seem to be used yet or useful lol
		
		enum CodingKeys: String, CodingKey {
			case id = "uuid"
		}
	}
}

struct BuddyLevel: Identifiable {
	var id: BuddyInfo.Level.ID
	var buddy: BuddyInfo
	
	init(_ buddy: BuddyInfo) {
		self.buddy = buddy
		// buddies currently only have one level, and we only care about the id (the image is the same and the name is wrong)
		self.id = buddy.levels.first!.id
	}
	
	func instance(_ instance: Weapon.Buddy.Instance.ID) -> Loadout.Gun.Buddy {
		.init(buddy: buddy.id, level: id, instance: instance)
	}
}
