import Foundation
import SwiftUI
import ValorantAPI
import CGeometry

extension AssetClient {
	func getMapInfo() async throws -> [MapInfo] {
		try await send(MapInfoRequest())
	}
}

private struct MapInfoRequest: AssetDataRequest {
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
	var callouts: [Callout]?
	
	var multiplier: CGSize {
		.init(width: xMultiplier, height: yMultiplier)
	}
	
	var offset: CGVector {
		.init(dx: xScalarToAdd, dy: yScalarToAdd)
	}
	
	func convert(_ position: CGPoint) -> CGPoint {
		// these are literally just flipped lmfao
		position.withFlippedAxes * multiplier + offset
	}
	
	struct Callout: Codable {
		var regionName: String
		var superRegionName: String
		var location: Position
		
		var point: CGPoint {
			CGPoint(location)
		}
		
		var fullName: String {
			"\(superRegionName) \(regionName)"
		}
	}
}
