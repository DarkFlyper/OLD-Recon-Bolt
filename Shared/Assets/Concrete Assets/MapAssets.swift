import Foundation
import SwiftUI
import ValorantAPI

extension AssetClient {
	func getMapInfo() async throws -> [MapInfo] {
		try await send(MapInfoRequest())
	}
}

private struct MapInfoRequest: AssetRequest {
	let path = "/v1/maps"
	
	typealias Response = [MapInfo]
}

struct MapInfo: AssetItem, Codable, Identifiable {
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
	
	func convert(position: Position) -> UnitPoint {
		// TODO: it might be more complicated than this (rotations?)
		UnitPoint(
			x: Double(position.x) * xMultiplier + xScalarToAdd,
			y: Double(position.y) * yMultiplier + yScalarToAdd
		)
	}
	
	var images: [AssetImage] {
		displayIcon
		listViewIcon
		splash
	}
}
