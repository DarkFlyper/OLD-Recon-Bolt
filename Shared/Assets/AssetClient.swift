import Foundation
import Protoquest
import HandyOperators

struct AssetClient {
	let baseURL = URL(string: "https://valorant-api.com")!
	
	let networkLayer: Protolayer
	
	private let shouldTrace = true
	
	init(networkLayer: Protolayer = .urlSession()) {
		self.networkLayer = networkLayer
	}
	
	func send<R: Request>(_ request: R) async throws -> R.Response {
		let urlRequest = try URLRequest(url: request.url(relativeTo: baseURL))
		<-  request.configure(_:)
		
		if shouldTrace {
			print(request, "sending request to", urlRequest.url!)
		}
		
		let response = try await networkLayer.send(urlRequest)
		
		if shouldTrace {
			print(request, "received response")
		}
		
		return try request.decodeResponse(from: response)
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
