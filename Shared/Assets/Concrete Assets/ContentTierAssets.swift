import SwiftUI
import ValorantAPI

extension AssetClient {
	func getContentTiers() async throws -> [ContentTier] {
		try await send(ContentTierRequest())
	}
}

private struct ContentTierRequest: AssetDataRequest {
	let path = "/v1/contenttiers"
	
	typealias Response = [ContentTier]
}

struct ContentTier: AssetItem, Codable, Identifiable {
	var id: ObjectID<Self, LowercaseUUID>
	var name: String
	var rank: Int
	@HexEncodedColor var color: Color?
	var displayIcon: AssetImage
	
	private enum CodingKeys: String, CodingKey {
		case id = "uuid"
		case name = "devName"
		case rank
		case color = "highlightColor"
		case displayIcon
	}
}
