import SwiftUI
import ValorantAPI

struct CompetitiveTier: AssetItem, Codable {
	var number: Int
	var name: String
	var division: String
	var divisionID: DivisionID // doesn't depend on language
	
	/// The tier's primary color.
	@HexEncodedColor var color: Color?
	/// The tier's background color.
	@HexEncodedColor var backgroundColor: Color?
	
	var icon: AssetImage?
	var rankTriangleDownwards: AssetImage?
	var rankTriangleUpwards: AssetImage?
	
	var isImmortalPlus: Bool {
		divisionID == .immortal || divisionID == .radiant
	}
	
	private enum CodingKeys: String, CodingKey {
		case number = "tier"
		case name = "tierName"
		case division = "divisionName"
		case divisionID = "division"
		case color
		case backgroundColor
		
		case icon = "largeIcon"
		case rankTriangleDownwards = "rankTriangleDownIcon"
		case rankTriangleUpwards = "rankTriangleUpIcon"
	}
	
	struct DivisionID: NamespacedID {
		static let immortal = Self("IMMORTAL")
		static let radiant = Self("RADIANT")
		
		static let namespace = "ECompetitiveDivision"
		var rawValue: String
	}
	
	struct Collection: AssetItem, Codable, Identifiable {
		var id: ObjectID<Self, LowercaseUUID>
		var tiers: [Int: CompetitiveTier] // tiers aren't necessarily contiguous! e.g. the second set of tiers skips 22 and 23.
		
		func tier(_ number: Int?) -> CompetitiveTier? {
			tiers[number ?? 0]
		}
		
		func lowestImmortalPlusTier() -> Int? {
			tiers.values
				.filter { $0.divisionID == .immortal }
				.map(\.number)
				.min()
		}
		
		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			self.id = try container.decode(ID.self, forKey: .id)
			
			if let tiers = try? container.decode([Int: CompetitiveTier].self, forKey: .tiers) {
				self.tiers = tiers
			} else {
				let rawTiers = try container.decode([CompetitiveTier].self, forKey: .tiers)
				self.tiers = .init(values: rawTiers, keyedBy: \.number)
			}
		}
		
		private enum CodingKeys: String, CodingKey {
			case id = "uuid"
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

extension CareerSummary {
	func peakRank(seasons: SeasonCollection.Accessor?) -> RankSnapshot? {
		guard let seasons, let bySeason = competitiveInfo?.bySeason else { return nil }
		return seasons.collection.actsInOrder
			.reversed() // most recent first
			.lazy
			.compactMap { act in bySeason[act.id]?.peakRank() }
			.max()
	}
	
	func peakRankInfo(seasons: SeasonCollection.Accessor?) -> CompetitiveTier? {
		peakRank(seasons: seasons)
			.flatMap { seasons?.tierInfo($0) }
	}
}
