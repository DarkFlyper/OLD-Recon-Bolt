import Foundation

extension AssetClient {
	func getCurrentVersion() -> BasicPublisher<AssetVersion> {
		send(VersionRequest())
	}
}

private struct VersionRequest: AssetRequest {
	let path = "/v1/version"
	
	typealias Response = AssetVersion
}

struct AssetVersion: Codable, Hashable {
	var branch: String
	var version: String
	var buildVersion: String
	var buildDate: Date
	var riotClientVersion: String
}
