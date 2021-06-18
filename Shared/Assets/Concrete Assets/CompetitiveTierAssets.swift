import SwiftUI
import ValorantAPI

extension AssetClient {
	func getCompetitiveTiers() async throws -> [CompetitiveTier.Episode] {
		try await send(CompetitiveTierRequest())
	}
}

private struct CompetitiveTierRequest: AssetRequest {
	let path = "/v1/competitivetiers"
	
	typealias Response = [CompetitiveTier.Episode]
}

struct CompetitiveTier: AssetItem, Codable {
	var number: Int
	var name: String
	var division: String
	/// The tier's primary color, as an RGBA hex string. Check out ``color``!
	var colorString: String
	
	/// The tier's primary color.
	var color: Color? {
		guard let raw = UInt32(colorString, radix: 16) else { return nil }
		return Color(
			red: Double(raw >> 24 & 0xFF) / 255,
			green: Double(raw >> 16 & 0xFF) / 255,
			blue: Double(raw >> 8 & 0xFF) / 255
		).opacity(Double(raw >> 0 & 0xFF) / 255)
	}
	
	var icon: AssetImage?
	var rankTriangleDownwards: AssetImage?
	var rankTriangleUpwards: AssetImage?
	
	var images: [AssetImage] {
		icon
		rankTriangleDownwards
		rankTriangleUpwards
	}
	
	private enum CodingKeys: String, CodingKey {
		case number = "tier"
		case name = "tierName"
		case division = "divisionName"
		case colorString = "color"
		
		case icon = "largeIcon"
		case rankTriangleDownwards = "rankTriangleDownIcon"
		case rankTriangleUpwards = "rankTriangleUpIcon"
	}
	
	struct Episode: AssetItem, Codable, Identifiable {
		var id: ObjectID<Self, UUID>
		var internalName: String
		var tiers: [CompetitiveTier]
		
		var images: [AssetImage] {
			tiers.flatMap(\.images)
		}
		
		private enum CodingKeys: String, CodingKey {
			case id = "uuid"
			case internalName = "assetObjectName"
			case tiers
		}
	}
}
