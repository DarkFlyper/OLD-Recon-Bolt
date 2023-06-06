import Foundation
import ValorantAPI

extension AssetClient {
	func getPlayerTitleInfo() async throws -> [PlayerTitleInfo] {
		try await send(PlayerTitleInfoRequest())
	}
}

private struct PlayerTitleInfoRequest: AssetDataRequest {
	let path = "/v1/playertitles"
	
	typealias Response = [PlayerTitleInfo]
}

struct PlayerTitleInfo: AssetItem, Codable, Identifiable {
	private var uuid: ID
	var id: PlayerTitle.ID { uuid }
	/// This is `nil` for the default title.
	var displayName: String?
	/// This is `nil` for the default title.
	var titleText: String?
	var isHiddenIfNotOwned: Bool
}
