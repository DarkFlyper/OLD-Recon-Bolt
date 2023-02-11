import Foundation
import ValorantAPI

extension AssetClient {
	func getPlayerCardInfo() async throws -> [PlayerCardInfo] {
		try await send(PlayerCardInfoRequest())
	}
}

private struct PlayerCardInfoRequest: AssetDataRequest {
	let path = "/v1/playercards"
	
	typealias Response = [PlayerCardInfo]
}

struct PlayerCardInfo: AssetItem, Codable, Identifiable {
	private var uuid: ID
	var id: PlayerCard.ID { uuid }
	var displayName: String
	var isHiddenIfNotOwned: Bool
	
	/// Small square icon.
	var smallArt: AssetImage
	/// Wide artwork used in the loading screen.
	var wideArt: AssetImage
	/// Tall artwork used in the lobby.
	var largeArt: AssetImage
}
