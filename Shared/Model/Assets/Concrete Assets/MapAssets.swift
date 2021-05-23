import Foundation
import ValorantAPI
import ArrayBuilder

extension AssetClient {
	func getMapInfo() -> BasicPublisher<[MapInfo]> {
		send(MapInfoRequest())
	}
}

private struct MapInfoRequest: AssetRequest {
	let path = "/v1/maps"
	
	typealias Response = [MapInfo]
}

struct MapInfo: Codable, Identifiable {
	private var mapUrl: MapID
	var id: MapID { mapUrl } // lazy rename
	var displayName: String
	var coordinates: String?
	/// the minimap (also used for game event visualization)
	var displayIcon: AssetImage?
	/// a smaller icon used in-game for lists
	var listViewIcon: AssetImage
	var splash: AssetImage
	var assetPath: String
	var xMultiplier, yMultiplier: Double
	var xScalarToAdd, yScalarToAdd: Double
	
	@ArrayBuilder<AssetImage>
	var images: [AssetImage] {
		displayIcon
		listViewIcon
		splash
	}
}
