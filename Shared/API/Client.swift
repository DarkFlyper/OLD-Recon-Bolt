import Foundation
import Combine
import HandyOperators

final class Client: Identifiable {
	let requestEncoder = JSONEncoder() <- {
		$0.keyEncodingStrategy = .convertToSnakeCase
	}
	let responseDecoder = JSONDecoder() <- {
		$0.keyDecodingStrategy = .convertFromSnakeCase
		$0.dateDecodingStrategy = .millisecondsSince1970
	}
	
	let session = URLSession(configuration: .ephemeral)
	let region: Region
	
	private var accessToken: String?
	private var entitlementsToken: String?
	
	static func authenticated(username: String, password: String, region: Region) -> AnyPublisher<Client, Error> {
		let client = Client(region: region)
		return client.establishSession()
			.flatMap { client.getAccessToken(username: username, password: password) }
			.map { client.accessToken = $0 }
			.flatMap { client.getEntitlementsToken() }
			.map { client.entitlementsToken = $0 }
			.map { client }
			.eraseToAnyPublisher()
	}
	
	private init(region: Region) {
		self.region = region
	}
	
	func send<R: Request>(_ request: R) -> AnyPublisher<R.Response, Error> {
		Just(request)
			.tryMap(rawRequest(for:))
			.flatMap { [session] in
				session.dataTaskPublisher(for: $0).mapError { $0 }
			}
			//.map { $0 <- { print("response: \(String(bytes: $0.data, encoding: .utf8)!)") } }
			.tryMap { [responseDecoder] in
				try request.decodeResponse(from: $0.data, using: responseDecoder)
			}
			.eraseToAnyPublisher()
	}
	
	private static let encodedPlatformInfo = (try! JSONEncoder().encode(PlatformInfo())).base64EncodedString()
	private func rawRequest<R: Request>(for request: R) throws -> URLRequest {
		try URLRequest(url: request.url) <- {
			try request.encode(to: &$0, using: requestEncoder)
			
			//print("sending request to \(request.url)")
			//$0.httpBody.map { print("request: \(String(bytes: $0, encoding: .utf8)!)") }
			
			if let token = accessToken {
				$0.setValue(token, forHTTPHeaderField: "Authorization")
			}
			if let token = entitlementsToken {
				$0.setValue(token, forHTTPHeaderField: "X-Riot-Entitlements-JWT")
			}
			$0.setValue(Self.encodedPlatformInfo, forHTTPHeaderField: "X-Riot-ClientPlatform")
		}
	}
}

private struct PlatformInfo: Encodable {
	let platformType = "PC"
	let platformOS = "Windows"
	let platformOSVersion = "10.0.19042.1.256.64bit"
	let platformChipset = "Unknown"
}
