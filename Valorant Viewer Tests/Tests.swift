import XCTest
import CombineExpectations
import HandyOperators
@testable import Valorant_Viewer

final class Tests: XCTestCase {
	func testDownloadingAssets() throws {
		let recorder = AssetManager.loadAssets(forceUpdate: true) { print($0) }.record()
		let startTime = Date()
		let assetCollection = try wait(for: recorder.single, timeout: 100, description: "load assets")
		XCTAssertFalse(assetCollection.agents.isEmpty)
		XCTAssertFalse(assetCollection.maps.isEmpty)
		//dump(assetCollection, maxDepth: 4)
		print(-startTime.timeIntervalSinceNow, "seconds")
	}
}

extension XCTestCase {
	func measureWithResult<T>(options: XCTMeasureOptions = .default, block: () throws -> T) throws -> T {
		var result: Result<T, Error>?
		measure(options: options) { result = .init(catching: block) }
		return try result!.get()
	}
}
