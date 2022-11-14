import Foundation
import ValorantAPI

extension AssetClient {
	func getObjectiveInfo() async throws -> [ObjectiveInfo] {
		try await send(ObjectiveInfoRequest())
	}
}

private struct ObjectiveInfoRequest: AssetDataRequest {
	let path = "/v1/objectives"
	
	typealias Response = [ObjectiveInfo]
}

struct ObjectiveInfo: AssetItem, Codable, Identifiable {
	typealias ID = Objective.ID
	
	private var uuid: ID
	var id: ID { uuid }
	
	var directive: String?
	var assetPath: String
}
