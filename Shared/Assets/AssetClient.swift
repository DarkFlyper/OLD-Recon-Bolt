import Foundation
import Protoquest
import HandyOperators

struct AssetClient {
	let baseURL = URL(string: "https://valorant-api.com")!
	
	var language: String
	let networkLayer: Protolayer
	
	private let shouldTrace = true
	
	init(language: String, networkLayer: Protolayer = .urlSession()) {
		self.language = language
		self.networkLayer = networkLayer
	}
	
	func send<R: Request>(_ request: R) async throws -> R.Response {
		let urlRequest = try URLRequest(url: request.url(relativeTo: baseURL))
		<- request.configure(_:)
		<- configureLanguage(of:)
		
		if shouldTrace {
			print(request, "sending request to", urlRequest.url!)
		}
		
		let response = try await networkLayer.send(urlRequest)
		
		if shouldTrace {
			print(request, "received response")
		}
		
		return try request.decodeResponse(from: response)
	}
	
	private func configureLanguage(of request: inout URLRequest) {
		var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
		components.queryItems = (components.queryItems ?? [])
		+ [.init(name: "language", value: language)]
		request.url = components.url!
	}
}

private struct AssetResponse<Body>: Decodable where Body: Decodable {
	var status: Int
	var data: Body
}

protocol AssetDataRequest: GetJSONRequest {}

extension AssetDataRequest {
	func decodeResponse(from raw: Protoresponse) throws -> Response {
		try raw
			.decodeJSON(as: AssetResponse<Response>.self, using: responseDecoder)
			.data
	}
}

private let responseDecoder = JSONDecoder() <- {
	$0.dateDecodingStrategy = .iso8601
}
