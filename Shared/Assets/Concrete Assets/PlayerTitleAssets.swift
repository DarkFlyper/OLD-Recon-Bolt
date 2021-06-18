import Foundation
import ValorantAPI

extension AssetClient {
	func getPlayerTitleInfo() async throws -> [PlayerTitleInfo] {
		try await send(PlayerTitleInfoRequest())
	}
}

private struct PlayerTitleInfoRequest: AssetRequest {
	let path = "/v1/playertitles"
	
	typealias Response = [PlayerTitleInfo]
}

struct PlayerTitleInfo: AssetItem, Codable, Identifiable {
	var id: PlayerTitle.ID
	/// This is `" "` (a singular space) for the default title.
	var displayName: String
	/// This is `nil` for the default title.
	var titleText: String?
	var isHiddenIfNotOwned: Bool
	
	private enum CodingKeys: String, CodingKey {
		case id = "uuid"
		case displayName
		case titleText
		case isHiddenIfNotOwned = "isbHiddenIfNotOwned" // lmao
	}
}
