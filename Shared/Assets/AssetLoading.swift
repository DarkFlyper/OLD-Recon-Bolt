import Foundation

extension AssetClient {
	func collectAssets(
		for version: AssetVersion,
		onProgress: AssetProgressCallback?
	) async throws -> AssetCollection {
		onProgress?(.init(completed: 0))
		
		async let maps = getMapInfo()
		async let agents = getAgentInfo()
		async let missions = getMissionInfo()
		async let gameModes = getGameModeInfo()
		async let objectives = getObjectiveInfo()
		async let playerCards = getPlayerCardInfo()
		async let playerTitles = getPlayerTitleInfo()
		async let weapons = getWeaponInfo()
		async let seasons = getSeasons()
		
		let collection = try await AssetCollection(
			version: version,
			maps: .init(values: maps),
			agents: .init(values: agents),
			missions: .init(values: missions),
			gameModes: .init(values: gameModes, keyedBy: { $0.gameID() }), // riot doesn't exactly seem to know the word "consistency"
			objectives: .init(values: objectives),
			playerCards: .init(values: playerCards),
			playerTitles: .init(values: playerTitles),
			weapons: .init(values: weapons),
			seasons: seasons
		)
		
		return try await downloadAllImages(for: collection, onProgress: onProgress)
	}
	
	private func downloadAllImages(
		for collection: AssetCollection,
		onProgress: AssetProgressCallback?
	) async throws -> AssetCollection {
		let images = collection.images
		
		try await withThrowingTaskGroup(of: Void.self) { group in
			for image in images {
				group.addTask {
					try await download(image)
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
		guard let total = total else { return 0 }
		return Double(completed) / Double(total)
	}
	
	var description: String {
		guard let total = total else { return "preparing to download assets…" }
		return "\(completed)/\(total) assets downloaded"
	}
}
