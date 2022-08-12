import Foundation
import Protoquest
import HandyOperators

struct AssetClient: Protoclient {
	let baseURL = URL(string: "https://valorant-api.com")!
	
	let responseDecoder = JSONDecoder() <- {
		$0.dateDecodingStrategy = .iso8601
	}
	
	let session: URLSession
	
	init(session: URLSession = .shared) {
		self.session = session
	}
	
	func addHeaders(to rawRequest: inout URLRequest) async throws {
		// band-aid fix to work around some people's internet being too slow
		// TODO: avoid having to download assets entirely (or at least not this many) and/or allow for partial progress
		rawRequest.timeoutInterval = 300
	}
	
	private let shouldTrace = true
	
	func traceOutgoing<R>(_ rawRequest: URLRequest, for request: R) where R : Request {
		guard shouldTrace else { return }
		print(request, "sending request to", rawRequest.url!)
	}
	
	func traceIncoming<R>(_ response: Protoresponse, for request: R) where R : Request {
		guard shouldTrace else { return }
		print(request, "received response")
	}
}

private struct AssetResponse<Body>: Decodable where Body: Decodable {
	var status: Int
	var data: Body
}

protocol AssetRequest: GetJSONRequest {}

extension AssetRequest {
	func decodeResponse(from raw: Protoresponse) throws -> Response {
		try raw
			.decodeJSON(as: AssetResponse<Response>.self)
			.data
	}
}
