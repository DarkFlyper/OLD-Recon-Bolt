import Foundation

extension AssetClient {
	func collectAssets(for version: AssetVersion) async throws -> AssetCollection {
		print("loading assets for version \(version) in language \(language)")
		
		async let maps = getMapInfo()
		async let agents = getAgentInfo()
		async let missions = getMissionInfo()
		async let contracts = getContractInfo()
		async let gameModes = getGameModeInfo()
		async let queues = getQueues()
		async let objectives = getObjectiveInfo()
		async let playerCards = getPlayerCardInfo()
		async let playerTitles = getPlayerTitleInfo()
		async let weapons = getWeaponInfo()
		async let seasons = getSeasons()
		async let sprays = getSprayInfo()
		async let buddies = getBuddyInfo()
		async let currencies = getCurrencyInfo()
		async let bundles = getBundleInfo()
		async let contentTiers = getContentTiers()
		
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
		
		let buddiesByLevelID = try await Dictionary(
			uniqueKeysWithValues: buddies.lazy.flatMap { buddy in
				buddy.levels.map { ($0.id, buddy.id) }
			}
		)
		
		return try await AssetCollection(
			version: version,
			language: language,
			maps: .init(values: maps),
			agents: .init(values: agents),
			missions: .init(values: missions),
			contracts: .init(values: contracts),
			// riot doesn't exactly seem to know the word "consistency":
			gameModes: .init(values: gameModes, keyedBy: { $0.gameID() }),
			queues: .init(values: queues),
			objectives: .init(values: objectives),
			playerCards: .init(values: playerCards),
			playerTitles: .init(values: playerTitles),
			weapons: .init(values: weapons),
			seasons: seasons,
			skinsByLevelID: skinsByLevelID,
			sprays: .init(values: sprays),
			buddies: .init(values: buddies),
			buddiesByLevelID: buddiesByLevelID,
			currencies: .init(values: currencies),
			bundles: .init(values: bundles),
			contentTiers: .init(values: contentTiers)
		)
	}
}
