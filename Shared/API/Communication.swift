import Foundation

let authBaseURL = URL(string: "https://auth.riotgames.com")!
let authAPIBaseURL = authBaseURL.appendingPathComponent("api/v1")
let entitlementsBaseURL = URL(string: "https://entitlements.auth.riotgames.com/api")!

protocol Request {
	var url: URL { get }
	
	func encode(to rawRequest: inout URLRequest, using encoder: JSONEncoder) throws
	
	associatedtype Response
	func decodeResponse(from raw: Data, using decoder: JSONDecoder) throws -> Response
}

typealias GetJSONRequest = GetRequest & JSONDecodingRequest
typealias JSONJSONRequest = JSONEncodingRequest & JSONDecodingRequest

// MARK: - Request Encoding

protocol GetRequest: Request {}

extension GetRequest {
	func encode(to rawRequest: inout URLRequest, using encoder: JSONEncoder) throws {}
}

protocol JSONEncodingRequest: Request where Self: Encodable {
	static var httpMethod: String { get }
}

extension JSONEncodingRequest {
	static var httpMethod: String { "POST" }
	
	func encode(to rawRequest: inout URLRequest, using encoder: JSONEncoder) throws {
		rawRequest.httpMethod = Self.httpMethod
		rawRequest.httpBody = try encoder.encode(self)
		rawRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
	}
}

// MARK: - Response Decoding

protocol JSONDecodingRequest: Request where Response: Decodable {}

extension JSONDecodingRequest {
	func decodeResponse(from raw: Data, using decoder: JSONDecoder) throws -> Response {
		do {
			return try decoder.decode(Response.self, from: raw)
		} catch let error as DecodingError {
			throw JSONDecodingError(error: error, toDecode: raw)
		}
	}
}

protocol RawDataRequest: Request where Response == Data {}

extension RawDataRequest {
	func decodeResponse(from raw: Data, using decoder: JSONDecoder) throws -> Response { raw }
}

protocol StringDecodingRequest: Request where Response == String {}

extension StringDecodingRequest {
	func decodeResponse(from raw: Data, using decoder: JSONDecoder) throws -> Response {
		String(bytes: raw, encoding: .utf8)!
	}
}

struct JSONDecodingError: LocalizedError {
	var error: DecodingError
	var toDecode: Data
	
	var errorDescription: String? {
		"""
		\(error.localizedDescription)
		
		The data to decode was:
		\(String(bytes: toDecode, encoding: .utf8)!)
		"""
	}
}
