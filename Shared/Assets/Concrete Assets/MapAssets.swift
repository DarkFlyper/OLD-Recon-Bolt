import Foundation
import SwiftUI
import ValorantAPI
import CGeometry

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
	var callouts: [Callout]?
	
	var multiplier: CGSize {
		.init(width: xMultiplier, height: yMultiplier)
	}
	
	var offset: CGVector {
		.init(dx: xScalarToAdd, dy: yScalarToAdd) + (Self.offsetAdjustments[id] ?? .zero)
	}
	
	// riot back at it again…
	private static let offsetAdjustments: [MapID: CGVector] = [
		.ascent: .init(dx: -0.390, dy: -0.390),
		.bind: .init(dx: -0.553, dy: -0.610),
		.breeze: .init(dx: -0.300, dy: -0.300),
		.haven: .init(dx: -0.734, dy: -0.736),
		.icebox: .init(dx: 0.240, dy: 0.235),
		.split: .init(dx: -0.540, dy: -0.490),
	]
	
	func convert(_ position: CGPoint) -> CGPoint {
		// these are literally just flipped lmfao
		let base = position * multiplier + offset
		return -base.withFlippedAxes + CGVector(.one) // remap to top-left origin
	}
	
	var images: [AssetImage] {
		displayIcon
		listViewIcon
		splash
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
