import XCTest
import HandyOperators
import Protoquest
@testable import Recon_Bolt

final class Tests: XCTestCase {
	private static let layer = Protolayer.urlSession().readRequest { request in
		if request.url?.pathExtension == "png" {
			throw IgnoredRequestError.image
		}
	}
	
	func testDownloadingAssets() async throws {
		let client = AssetClient(networkLayer: Self.layer)
		let version = try await client.getCurrentVersion()
		let assetCollection = try await client.collectAssets(for: version)
		
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
	
	enum IgnoredRequestError: Error {
		case image
	}
}

extension XCTestCase {
	func measureWithResult<T>(options: XCTMeasureOptions = .default, block: () throws -> T) throws -> T {
		var result: Result<T, Error>?
		measure(options: options) { result = .init(catching: block) }
		return try result!.get()
	}
}
