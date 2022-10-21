import SwiftUI
import HandyOperators
import UserDefault
import Combine

@MainActor
final class ImageManager: ObservableObject {
	private var states: [AssetImage: ImageState] = [:]
	private var images: [AssetImage: UIImage] = [:]
	
	private let cache: ImageCache
	private let updater: Updater
	private var stateUpdateToken: AnyCancellable?
	
	// can't have a nonisolated wrapped property
	private enum VersionHolder {
		@UserDefault("ImageManager.version")
		static var version = ""
	}
	
	@MainActor
	init() {
		cache = .init()
		updater = .init(cache: cache)
		stateUpdateToken = updater.stateUpdates
			.collect(.byTime(RunLoop.main, .milliseconds(50)))
			.sink { updates in
				// TODO: check how much overhead this is adding (wish it wasn't necessary)
				Task { @MainActor [weak self] in
					self?.apply(updates)
				}
			}
	}
	
	func setVersion(_ version: AssetVersion) {
		guard version.riotClientVersion != VersionHolder.version else { return }
		VersionHolder.version = version.riotClientVersion
		states = [:] // make images re-check for the new version
	}
	
	func state(for image: AssetImage) -> ImageState? {
		states[image]
	}
	
	/// gets an image's current state and starts a download task if appropriate
	func image(for image: AssetImage?) -> UIImage? {
		guard let image else { return nil }
		if shouldDownload(image) {
			Task { await updater.download(image) }
		}
		
		switch cache.state(for: image) {
		case .cached(let image):
			return image
		case .tooLarge:
			return image.load()
		case .missing, nil:
			return nil
		}
	}
	
	func download(_ image: AssetImage) async {
		guard shouldDownload(image) else { return }
		await updater.download(image)
	}
	
	func shouldDownload(_ image: AssetImage) -> Bool {
		switch state(for: image) {
		case nil, .errored:
			return true
		case .downloading, .available:
			return false
		}
	}
	
	func cacheState(for image: AssetImage, loadImmediately: Bool = false) -> CacheState? {
		if loadImmediately, cache.state(for: image) == nil {
			cache.updateState(for: image, forceUpdate: false)
		}
		return cache.state(for: image)
	}
	
	private func apply(_ updates: some Sequence<StateUpdate>) {
		// batch updates to reduce CA commits
		objectWillChange.send()
		for update in updates {
			states[update.image] = update.state
		}
	}
	
	@MainActor
	func clear() {
		states = [:]
		cache.reset()
		try? AssetImage.removeCachedFiles()
		// if any loads are in progress, they might still set the state right after this, but i've decided i don't care
	}
	
	enum ImageState {
		case downloading
		case errored(Error)
		case available
	}
	
	enum CacheState: Equatable {
		case missing
		case cached(UIImage)
		case tooLarge
	}
	
	private struct StateUpdate {
		var image: AssetImage
		var state: ImageState
	}
	
	@MainActor
	private final class ImageCache {
		// caching these helps a lot with performance
		// nil means image loading was attempted but failed
		private var cached: [AssetImage: CacheState] = [:]
		
		private static let cacheSizeLimit = 256 * 256 // pixels
		
		private static func shouldCache(_ image: UIImage) -> Bool {
			guard let raw = image.cgImage else { return false }
			return raw.width * raw.height <= Self.cacheSizeLimit
		}
		
		func state(for image: AssetImage) -> CacheState? {
			cached[image]
		}
		
		func updateState(for image: AssetImage, forceUpdate: Bool) {
			if !forceUpdate, cached[image] != nil { return }
			cached[image] = newState(for: image)
		}
		
		private func newState(for image: AssetImage) -> CacheState {
			guard let loaded = image.load() else { return .missing }
			guard Self.shouldCache(loaded) else { return .tooLarge }
			return .cached(loaded)
		}
		
		func reset() {
			cached = [:]
		}
	}
	
	private final actor Updater {
		private var inProgress: Set<AssetImage> = []
		private let client = AssetClient()
		
		let stateUpdates = PassthroughSubject<StateUpdate, Never>()
		let cache: ImageCache
		
		init(cache: ImageCache) {
			self.cache = cache
		}
		
		func download(_ image: AssetImage) async {
			guard inProgress.insert(image).inserted else { return }
			defer { inProgress.remove(image) }
			
			if image.hasMetadata {
				do {
					let meta = try image.loadMetadata()
					// already checked against this version
					if meta.lastVersionCheckedAgainst == VersionHolder.version {
						await cache.updateState(for: image, forceUpdate: false)
						enqueueUpdate(of: image, to: .available)
						return
					}
				} catch {
					print("could not load metadata for \(image): \(error)")
				}
			}
			
			do {
				enqueueUpdate(of: image, to: .downloading)
				let wasReplaced = try await client.ensureDownloaded(image)
				await cache.updateState(for: image, forceUpdate: wasReplaced)
				enqueueUpdate(of: image, to: .available)
			} catch {
				print("error loading image from \(image.url) stored at \(image.localURL):")
				dump(error)
				enqueueUpdate(of: image, to: .errored(error))
				return
			}
			
			var meta = (try? image.loadMetadata()) ?? .init(
				versionDownloaded: VersionHolder.version,
				lastVersionCheckedAgainst: VersionHolder.version
			)
			meta.lastVersionCheckedAgainst = VersionHolder.version
			do {
				try image.save(meta)
			} catch {
				print("could not save metadata for \(image): \(error)")
			}
		}
		
		private func enqueueUpdate(of image: AssetImage, to state: ImageState) {
			stateUpdates.send(.init(image: image, state: state))
		}
	}
}

private struct ImageMetadata: Codable {
	var versionDownloaded: String
	var lastVersionCheckedAgainst: String
}

private extension AssetImage {
	var metadataURL: URL {
		localURL.deletingPathExtension().appendingPathExtension("json")
	}
	
	var hasMetadata: Bool {
		FileManager.default.fileExists(atPath: metadataURL.path)
	}
	
	func loadMetadata() throws -> ImageMetadata {
		try JSONDecoder().decode(ImageMetadata.self, from: Data(contentsOf: metadataURL))
	}
	
	func save(_ metadata: ImageMetadata) throws {
		try JSONEncoder().encode(metadata).write(to: metadataURL)
	}
}
