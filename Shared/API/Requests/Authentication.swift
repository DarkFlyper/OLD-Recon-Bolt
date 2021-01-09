import Foundation
import Combine
import HandyOperators

struct CookiesRequest: JSONJSONRequest {
	typealias Response = AuthenticationResponse
	
	var url: URL { authAPIBaseURL.appendingPathComponent("authorization") }
	
	let clientID = "play-valorant-web-prod"
	let responseType = "token id_token"
	let redirectURI = "https://playvalorant.com/"
	let nonce = 1
	let scope = "account openid"
}

struct AccessTokenRequest: JSONJSONRequest {
	typealias Response = AuthenticationResponse
	
	static let httpMethod = "PUT"
	var url: URL { authAPIBaseURL.appendingPathComponent("authorization") }
	
	let type = AuthMessageType.auth
	var username, password: String
}

struct AuthenticationResponse: Decodable {
	var type: AuthMessageType
	
	var error: String?
	var response: AccessTokenInfo?
	
	struct AccessTokenInfo: Decodable {
		var mode: String // fragment
		var parameters: Parameters
		
		func extractAccessToken() -> String {
			assert(mode == "fragment")
			
			let components = URLComponents(url: parameters.uri, resolvingAgainstBaseURL: false)!
			let values = [String: String](
				uniqueKeysWithValues: components.fragment!
					.split(separator: "&")
					.map {
						let parts = $0.components(separatedBy: "=")
						assert(parts.count == 2)
						return (parts.first!, parts.last!)
					}
			)
			
			return "\(values["token_type"]!) \(values["access_token"]!)"
		}
		
		struct Parameters: Decodable {
			var uri: URL
		}
	}
}

struct CommunicationMetadata: Codable {
	var type: AuthMessageType
	var country: String
}

enum AuthMessageType: String, Hashable, Codable {
	case auth
	case response
	case error
}

extension Client {
	func establishSession() -> AnyPublisher<Void, Error> {
		send(CookiesRequest())
			.map { (response: AuthenticationResponse) in // takes forever to compile without this
				assert(response.type == .auth && response.error == nil)
			}
			.eraseToAnyPublisher()
	}
	
	func getAccessToken(username: String, password: String) -> AnyPublisher<String, Error> {
		send(AccessTokenRequest(username: username, password: password))
			.tryMap { response in
				guard response.type != .auth else {
					throw AuthenticationError(message: response.error ?? "<no message given>")
				}
				assert(response.type == .response && response.error == nil)
				
				return response.response!.extractAccessToken()
			}
			.eraseToAnyPublisher()
	}
}

struct AuthenticationError: LocalizedError {
	static var messageOverrides = [
		"auth_failure": "Invalid username or password."
	]
	
	var message: String
	
	var errorDescription: String? {
		Self.messageOverrides[message] ?? message
	}
}
