import Foundation
import Protoquest
import HandyOperators
import ValorantAPI

final class HenrikClient {
	static let shared = HenrikClient()
	
	let baseURL = URL(string: "https://api.henrikdev.xyz/valorant/v1/account")!
	let layer = Protolayer.urlSession(.shared)
	
	private init() {}
	
	func send<R: HenrikRequest>(_ request: R) async throws -> R.Response {
		let urlRequest = try URLRequest(url: request.url(relativeTo: baseURL))
		<- request.configure(_:)
		let response = try await layer.send(urlRequest)
		return try request.decodeResponse(from: response)
	}
}

struct HenrikAPIError: Error, LocalizedError {
	let status: Int
	let message: String
	
	var errorDescription: String? {
		"[\(status)] \(!message.isEmpty ? message : "No message provided.")"
	}
}

private struct HenrikResponse<Body>: Decodable where Body: Decodable {
	var status: Int
	var data: Body?
	var errors: [HenrikError]?
	
	struct HenrikError: Codable {
		var code: Int?
		var message: String?
		var details: String?
	}
}

protocol HenrikRequest: GetJSONRequest {}

private let responseDecoder = JSONDecoder() <- {
	$0.keyDecodingStrategy = .convertFromSnakeCase
}

extension HenrikRequest {
	func decodeResponse(from raw: Protoresponse) throws -> Response {
		let response = try raw.decodeJSON(as: HenrikResponse<Response>.self, using: responseDecoder)
		guard let data = response.data else {
			let message = response.errors?.lazy
				.flatMap { [$0.message, $0.details] }
				.compacted()
				.joined(separator: "\n") ?? ""
			throw HenrikAPIError(status: response.status, message: message)
		}
		return data
	}
}

extension HenrikClient {
	func lookUpPlayer(name: String, tag: String) async throws -> (User, Location) {
		let response = try await send(PlayerLookupRequest(name: name, tag: tag))
		let user = User(id: response.puuid, gameName: response.name, tagLine: response.tag)
		let location = try Location.location(forRegion: response.region)
		??? PlayerLookupError.invalidRegion(response.region)
		return (user, location)
	}
}

enum PlayerLookupError: Error {
	case invalidRegion(String)
}

private struct PlayerLookupRequest: HenrikRequest {
	var name: String
	var tag: String
	
	var path: String {
		"\(name)/\(tag)"
	}
	
	struct Response: Decodable {
		var puuid: Player.ID
		var region: String
		var accountLevel: Int
		var name: String
		var tag: String
	}
}
