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
	
	/// The tier's primary color.
	@HexEncodedColor var color: Color?
	/// The tier's background color.
	@HexEncodedColor var backgroundColor: Color?
	
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
		case color
		case backgroundColor
		
		case icon = "largeIcon"
		case rankTriangleDownwards = "rankTriangleDownIcon"
		case rankTriangleUpwards = "rankTriangleUpIcon"
	}
	
	struct Episode: AssetItem, Codable, Identifiable {
		var id: ObjectID<Self, LowercaseUUID>
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

@propertyWrapper
struct HexEncodedColor: Codable {
	let wrappedValue: Color?
	
	let hex: String
	
	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		hex = try container.decode(String.self)
		wrappedValue = .init(hex: hex)
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(hex)
	}
}

private extension Color {
	init?(hex: String) {
		guard let raw = UInt32(hex, radix: 16) else { return nil }
		self = Color(
			red: Double(raw >> 24 & 0xFF) / 255,
			green: Double(raw >> 16 & 0xFF) / 255,
			blue: Double(raw >> 8 & 0xFF) / 255
		).opacity(Double(raw >> 0 & 0xFF) / 255)
	}
}
