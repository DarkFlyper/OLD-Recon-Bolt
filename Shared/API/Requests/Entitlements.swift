import Foundation
import Combine

struct EntitlementsTokenRequest: JSONJSONRequest {
	var url: URL { entitlementsBaseURL.appendingPathComponent("token/v1") }
	
	struct Response: Decodable {
		var entitlementsToken: String
	}
}

extension Client {
	func getEntitlementsToken() -> AnyPublisher<String, Error> {
		send(EntitlementsTokenRequest())
			.map(\.entitlementsToken)
			.eraseToAnyPublisher()
	}
}
