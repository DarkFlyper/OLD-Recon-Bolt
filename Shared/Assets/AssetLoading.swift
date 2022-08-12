import Foundation

extension AssetClient {
	func collectAssets(
		for version: AssetVersion,
		skipExistingImages: Bool,
		onProgress: AssetProgressCallback?
	) async throws -> AssetCollection {
		onProgress?(.init(completed: 0))
		
		async let maps = getMapInfo()
		async let agents = getAgentInfo()
		async let missions = getMissionInfo()
		async let contracts = getContractInfo()
		async let gameModes = getGameModeInfo()
		async let objectives = getObjectiveInfo()
		async let playerCards = getPlayerCardInfo()
		async let playerTitles = getPlayerTitleInfo()
		async let weapons = getWeaponInfo()
		async let seasons = getSeasons()
		async let sprays = getSprayInfo()
		async let buddies = getBuddyInfo()
		async let currencies = getCurrencyInfo()
		async let bundles = getBundleInfo()
		
		// this seems to be what skins are actually referred to by…
		let skinsByLevelID = try await Dictionary(
			uniqueKeysWithValues: weapons.lazy.flatMap { weapon in
				weapon.skins.enumerated().lazy.flatMap { skinIndex, skin in
					skin.levels.enumerated().map { levelIndex, level in
						(level.id, WeaponSkin.Level.Path(weapon: weapon.id, skinIndex: skinIndex, levelIndex: levelIndex))
					}
				}
			}
		)
		
		let collection = try await AssetCollection(
			version: version,
			maps: .init(values: maps),
			agents: .init(values: agents),
			missions: .init(values: missions),
			contracts: .init(values: contracts),
			// riot doesn't exactly seem to know the word "consistency":
			gameModes: .init(values: gameModes, keyedBy: { $0.gameID() }),
			objectives: .init(values: objectives),
			playerCards: .init(values: playerCards),
			playerTitles: .init(values: playerTitles),
			weapons: .init(values: weapons),
			seasons: seasons,
			skinsByLevelID: skinsByLevelID,
			sprays: .init(values: sprays),
			buddies: .init(values: buddies),
			currencies: .init(values: currencies),
			bundles: .init(values: bundles)
		)
		
		return try await downloadAllImages(for: collection, skipExistingImages: skipExistingImages, onProgress: onProgress)
	}
	
	private func downloadAllImages(
		for collection: AssetCollection,
		skipExistingImages: Bool,
		onProgress: AssetProgressCallback?
	) async throws -> AssetCollection {
		let images = collection.images
		
		try await withThrowingTaskGroup(of: Void.self) { group in
			for image in images {
				group.addTask {
					try await download(image, skipIfExists: skipExistingImages)
				}
			}
			onProgress?(.init(completed: 0, total: images.count))
			var completed = 0
			for try await _ in group {
				completed += 1 // no async zip yet
				onProgress?(.init(completed: completed, total: images.count))
			}
		}
		
		return collection
	}
}

typealias AssetProgressCallback = (AssetDownloadProgress) -> Void
struct AssetDownloadProgress: CustomStringConvertible {
	var completed: Int
	var total: Int?
	
	var fractionComplete: Double {
		guard let total else { return 0 }
		return Double(completed) / Double(total)
	}
	
	var description: String {
		guard let total else { return "preparing to download assets…" }
		return "\(completed)/\(total) assets downloaded"
	}
}
