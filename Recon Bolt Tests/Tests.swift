import XCTest
import HandyOperators
@testable import Recon_Bolt

final class Tests: XCTestCase {
	private static let session = URLSession(configuration: URLSessionConfiguration.default <- {
		$0.protocolClasses!.insert(ImageIgnoringProtocol.self, at: 0)
	})
	
	func testDownloadingAssets() async throws {
		let client = AssetClient(session: Self.session)
		let version = try await client.getCurrentVersion()
		let assetCollection = try await client.collectAssets(for: version) { print($0) }
		
		XCTAssertFalse(assetCollection.agents.isEmpty)
		XCTAssertFalse(assetCollection.maps.isEmpty)
		let skinCount = assetCollection.weapons.values.lazy.flatMap(\.skins).count
		print(skinCount, "skins")
		
		let encoder = JSONEncoder() <- { $0.outputFormatting = .prettyPrinted }
		let encoded = try encoder.encode(assetCollection)
		// for debugging:
		//print(String(bytes: encoded, encoding: .utf8)!)
		XCTAssertNoThrow(try JSONDecoder().decode(AssetCollection.self, from: encoded))
	}
}

extension XCTestCase {
	func measureWithResult<T>(options: XCTMeasureOptions = .default, block: () throws -> T) throws -> T {
		var result: Result<T, Error>?
		measure(options: options) { result = .init(catching: block) }
		return try result!.get()
	}
}

final class ImageIgnoringProtocol: URLProtocol {
	override class func canInit(with task: URLSessionTask) -> Bool {
		task.currentRequest.map(canInit(with:)) ?? false
	}
	
	override class func canInit(with request: URLRequest) -> Bool {
		request.url?.pathExtension == "png"
	}
	
	override class func canonicalRequest(for request: URLRequest) -> URLRequest {
		request
	}
	
	override func startLoading() {
		client?.urlProtocol(self, didReceive: HTTPURLResponse(), cacheStoragePolicy: .notAllowed)
		client?.urlProtocol(self, didLoad: Data())
		client?.urlProtocolDidFinishLoading(self)
	}
	
	override func stopLoading() {}
}
