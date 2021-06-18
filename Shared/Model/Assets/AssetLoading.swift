import Foundation

extension AssetClient {
	func collectAssets(
		for version: AssetVersion,
		onProgress: AssetProgressCallback?
	) async throws -> AssetCollection {
		async let maps = getMapInfo()
		async let agents = getAgentInfo()
		async let missions = getMissionInfo()
		async let objectives = getObjectiveInfo()
		async let playerCards = getPlayerCardInfo()
		async let playerTitles = getPlayerTitleInfo()
		async let competitiveTiers = getCompetitiveTiers()
		
		let collection = try await AssetCollection(
			version: version,
			maps: .init(values: maps),
			agents: .init(values: agents),
			missions: .init(values: missions),
			objectives: .init(values: objectives),
			playerCards: .init(values: playerCards),
			playerTitles: .init(values: playerTitles),
			competitiveTierEpisodes: competitiveTiers
		)
		
		return try await downloadAllImages(for: collection, onProgress: onProgress)
	}
	
	private func downloadAllImages(
		for collection: AssetCollection,
		onProgress: AssetProgressCallback?
	) async throws -> AssetCollection {
		let images = collection.images
		
		// TODO: limit concurrency with semaphore or something?
		try await withThrowingTaskGroup(of: Void.self) { group in
			for image in images {
				group.async {
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
	var completed, total: Int
	
	var fractionComplete: Double {
		Double(completed) / Double(total)
	}
	
	var description: String {
		"\(completed)/\(total) assets downloaded"
	}
}
