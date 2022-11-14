import Foundation
import ValorantAPI

extension AssetClient {
	func getSprayInfo() async throws -> [SprayInfo] {
		try await send(SprayInfoRequest())
	}
}

private struct SprayInfoRequest: AssetDataRequest {
	let path = "/v1/sprays"
	
	typealias Response = [SprayInfo]
}

struct SprayInfo: AssetItem, Codable, Identifiable {
	var id: Spray.ID
	var displayName: String
	var displayIcon: AssetImage
	var fullIcon: AssetImage?
	var category: Category?
	
	var bestIcon: AssetImage { fullIcon ?? displayIcon }
	
	private enum CodingKeys: String, CodingKey {
		case id = "uuid"
		case displayName
		case displayIcon
		case category
		case fullIcon = "fullTransparentIcon"
	}
	
	struct Category: NamespacedID {
		/// this seems to mean the spray cannot be used mid-round because it's too distracting
		static let contextual = Self("Contextual")
		
		static let namespace = "EAresSprayCategory"
		var rawValue: String
	}
}
