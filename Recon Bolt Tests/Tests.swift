import XCTest
import HandyOperators
import Protoquest
import ValorantAPI
@testable import Recon_Bolt

final class Tests: XCTestCase {
	private static let layer = Protolayer.urlSession().readRequest { request in
		if request.url?.pathExtension == "png" {
			throw IgnoredRequestError.image
		}
	}
	
	func testDownloadingAssets() async throws {
		let client = AssetClient(language: "en-US", networkLayer: Self.layer)
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
	
	/// useful for translators
	func testPrintingLevelItemLocations() async throws {
		let client = AssetClient(language: "en-US", networkLayer: Self.layer)
		let weapons = try await client.getWeaponInfo()
		
		typealias LevelItem = WeaponSkin.Level.Item
		
		let guns: [WeaponSkin.ID: Weapon.ID] = .init(
			uniqueKeysWithValues: weapons.lazy.flatMap { weapon in
				weapon.skins.lazy.map { ($0.id, weapon.id) }
			}
		)
		
		let byLevelItem: [LevelItem: [WeaponSkin]] = weapons
			.lazy
			.flatMap(\.skins)
			.flatMap { (skin: WeaponSkin) in
				skin.levels.compactMap { level in
					level.levelItem.map { ($0, skin) }
				}
			}
			.reduce(into: [:]) { dict, level in
				dict[level.0, default: []].append(level.1)
			}
		let byRarity = byLevelItem.sorted(on: \.value.count)
		var handled: Set<LevelItem> = []
		for (item, skins) in byRarity {
			guard !handled.contains(item) else { continue }
			
			// prefer vandal, then phantom, then the rest
			let skin = nil
			?? skins.first { guns[$0.id]! == .vandal }
			?? skins.first { guns[$0.id]! == .phantom }
			?? skins.first!
			
			print()
			print(skin.displayName)
			for (index, level) in skin.levels.enumerated() {
				guard let item = level.levelItem else { continue }
				let style = handled.contains(item) ? "" : "**"
				print("- \(style)Level \(index + 1): \(item.rawValue)\(style)")
				handled.insert(item)
			}
		}
		print()
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
