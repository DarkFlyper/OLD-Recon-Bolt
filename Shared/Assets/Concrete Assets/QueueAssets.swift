import Foundation
import ValorantAPI

extension AssetClient {
	func getQueues() async throws -> [QueueInfo] {
		try await send(QueueInfoRequest())
	}
}

private struct QueueInfoRequest: AssetDataRequest {
	let path = "/v1/gamemodes/queues"
	
	typealias Response = [QueueInfo]
}

struct QueueInfo: AssetItem, Codable, Identifiable {
	var id: QueueID
	var name: String
	var capsName: String
	var description: String?
	
	private enum CodingKeys: String, CodingKey {
		case id = "queueId"
		case name = "dropdownText"
		case capsName = "selectedText"
		case description
	}
}
