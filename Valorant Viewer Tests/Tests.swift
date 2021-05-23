import XCTest
import CombineExpectations
import HandyOperators
@testable import Valorant_Viewer

final class Tests: XCTestCase {
	private static let session = URLSession(configuration: URLSessionConfiguration.default <- {
		$0.protocolClasses!.insert(ImageIgnoringProtocol.self, at: 0)
	})
	
	func testDownloadingAssets() throws {
		let client = AssetClient(session: Self.session)
		let recorder = client.getCurrentVersion()
			.flatMap { client.collectAssets(for: $0) { print($0) } }
			.record()
		
		let assetCollection = try wait(for: recorder.single, timeout: 100, description: "load assets")
		XCTAssertFalse(assetCollection.agents.isEmpty)
		XCTAssertFalse(assetCollection.maps.isEmpty)
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
