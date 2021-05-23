import Foundation
import Combine

extension AssetClient {
	func collectAssets(
		for version: AssetVersion,
		onProgress: AssetProgressCallback?
	) -> BasicPublisher<AssetCollection> {
		// can't wait for async/await
		getMapInfo()
			.zip(
				getAgentInfo(),
				getMissionInfo(),
				getObjectiveInfo()
			) { (maps, agents, missions, objectives) in
				AssetCollection(
					version: version,
					maps: .init(values: maps),
					agents: .init(values: agents),
					missions: .init(values: missions),
					objectives: .init(values: objectives)
				)
			}
			.flatMap { downloadAllImages(for: $0, onProgress: onProgress) }
			.eraseToAnyPublisher()
	}
	
	private func downloadAllImages(
		for collection: AssetCollection,
		onProgress: AssetProgressCallback?
	) -> BasicPublisher<AssetCollection> {
		let images = collection.images
		var completed: Int32 = 0
		onProgress?(.init(completed: 0, total: images.count))
		
		let concurrencyLimiter = DispatchSemaphore(value: 4) // this doesn't seem to slow it down and makes it more consistent
		let scheduler = DispatchQueue(label: "image downloads", qos: .userInitiated)
		return images.publisher
			.receive(on: scheduler)
			.also { _ in concurrencyLimiter.wait() }
			.flatMap(download(_:))
			.also { _ in concurrencyLimiter.signal() }
			.also { onProgress?(.init(completed: Int(OSAtomicIncrement32(&completed)), total: images.count)) }
			.collect()
			.map { _ in collection }
			.eraseToAnyPublisher()
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
