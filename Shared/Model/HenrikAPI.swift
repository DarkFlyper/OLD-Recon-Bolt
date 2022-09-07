import Foundation
import Protoquest
import HandyOperators
import ValorantAPI

final class HenrikClient: Protoclient {
	static let shared = HenrikClient()
	
	let baseURL = URL(string: "https://api.henrikdev.xyz/valorant/v1/account")!
	
	let responseDecoder = JSONDecoder() <- {
		$0.keyDecodingStrategy = .convertFromSnakeCase
	}
	
	private init() {}
	
	struct APIError: Error, LocalizedError {
		let status: Int
		let message: String
		
		var errorDescription: String? {
			"[\(status)] \(!message.isEmpty ? message : "No message provided.")"
		}
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

extension HenrikRequest {
	func decodeResponse(from raw: Protoresponse) throws -> Response {
		let response = try raw.decodeJSON(as: HenrikResponse<Response>.self)
		guard let data = response.data else {
			let message = response.errors?.lazy
				.flatMap { [$0.message, $0.details] }
				.compacted()
				.joined(separator: "\n") ?? ""
			throw HenrikClient.APIError(status: response.status, message: message)
		}
		return data
	}
}

extension HenrikClient {
	func lookUpPlayer(name: String, tag: String) async throws -> User {
		let response = try await send(PlayerLookupRequest(name: name, tag: tag))
		let user = User(id: response.puuid, gameName: response.name, tagLine: response.tag)
		// TODO: handle different regions!!
		return user
	}
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
