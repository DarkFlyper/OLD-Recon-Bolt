import Foundation
import ValorantAPI
import UserDefault
import Combine
import SwiftUI

final class AssetManager: ObservableObject {
	typealias BasicPublisher = AssetClient.BasicPublisher
	
	@Published private(set) var assets: AssetCollection?
	@Published private(set) var progress: AssetDownloadProgress?
	@Published private(set) var error: Error?
	private var loadTask: AnyCancellable?
	
	init() {
		loadTask = Self
			.loadAssets() { progress in
				DispatchQueue.main.async {
					print(progress)
					self.progress = progress
				}
			}
			.receive(on: DispatchQueue.main)
			.sinkResult { self.assets = $0 }
				onFailure: { self.error = $0 }
				always: { self.progress = nil }
	}
	
	static let forPreviews = AssetManager(assets: stored)
	
	private init(assets: AssetCollection?) {
		self.assets = assets
	}
	
	static func loadAssets(forceUpdate: Bool = false, onProgress: AssetProgressCallback? = nil) -> BasicPublisher<AssetCollection> {
		client.getCurrentVersion()
			.flatMap { [client] version -> BasicPublisher<AssetCollection> in
				if !forceUpdate, let stored = stored, stored.version == version {
					return Just(stored)
						.setFailureType(to: Error.self)
						.eraseToAnyPublisher()
				} else {
					return client
						.collectAssets(for: version, onProgress: onProgress)
						.also { Self.stored = $0 }
						.eraseToAnyPublisher()
				}
			}
			.eraseToAnyPublisher()
	}
	
	@UserDefault("AssetManager.stored") // TODO: this doesn't work for iOS :<
	fileprivate static var stored: AssetCollection?
	
	private static let client = AssetClient()
}

typealias AssetProgressCallback = (AssetDownloadProgress) -> Void
struct AssetDownloadProgress {
	var completed, total: Int
	
	var fractionComplete: Double {
		Double(completed) / Double(total)
	}
}

extension AssetDownloadProgress: CustomStringConvertible {
	var description: String {
		"\(completed)/\(total) assets downloaded"
	}
}

struct AssetCollection: Codable {
	let version: AssetVersion
	
	let maps: [MapID: MapInfo]
	let agents: [Agent.ID: AgentInfo]
	
	var images: Set<AssetImage> {
		Set(maps.values.flatMap(\.images) + agents.values.flatMap(\.images))
	}
}

extension AssetCollection: DefaultsValueConvertible {}

extension AssetClient {
	fileprivate func collectAssets(for version: AssetVersion, onProgress: AssetProgressCallback?) -> BasicPublisher<AssetCollection> {
		// can't wait for async/await
		getMapInfo()
			.zip(getAgentInfo())
			.map { (maps, agents) in
				AssetCollection(
					version: version,
					maps: .init(uniqueKeysWithValues: maps.map { ($0.id, $0) }),
					agents: .init(uniqueKeysWithValues: agents.map { ($0.id, $0) })
				)
			}
			.flatMap { downloadAllImages(for: $0, onProgress: onProgress) }
			.eraseToAnyPublisher()
	}
	
	private func downloadAllImages(for collection: AssetCollection, onProgress: AssetProgressCallback?) -> BasicPublisher<AssetCollection> {
		let images = collection.images
		var completed: Int32 = 0
		onProgress?(.init(completed: 0, total: images.count))
		let concurrencyLimiter = DispatchSemaphore(value: 2) // this doesn't seem to slow it down and makes it more consistent
		let scheduler = DispatchQueue(label: "image downloads", qos: .userInitiated)
		return images.publisher
			.receive(on: scheduler)
			.also { _ in concurrencyLimiter.wait() }
			.flatMap(download(_:))
			.also { _ in concurrencyLimiter.signal() }
			.also { onProgress?(.init(completed: Int(OSAtomicIncrement32(&completed)), total: images.count)) }
			.collect()
			.map { (_: [Void]) in collection }
			.eraseToAnyPublisher()
	}
}

struct AssetManager_Previews: PreviewProvider {
	static var previews: some View {
		PreviewView()
	}
	
	private struct PreviewView: View {
		@StateObject var manager = AssetManager()
		
		var body: some View {
			VStack {
				Text(verbatim: "stored: \(AssetManager.stored as Any)")
				Text(verbatim: "\(manager.progress?.description ?? "nothing in progress")")
			}
			.padding()
			.previewLayout(.sizeThatFits)
		}
	}
}
