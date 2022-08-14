import SwiftUI
import HandyOperators
import UserDefault

@MainActor
final class ImageManager: ObservableObject {
	@UserDefault("ImageManager.version")
	private static var version = ""
	
	@Published private var states: [AssetImage: ImageState] = [:]
	private var inProgress: Set<AssetImage> = []
	private let client = AssetClient()
	
	nonisolated init() {
		Task { @MainActor in
			Self.version = try await client.getCurrentVersion().riotClientVersion
		}
	}
	
	func setVersion(_ version: AssetVersion) {
		Self.version = version.riotClientVersion
		// TODO: invalidate images?
	}
	
	func state(for image: AssetImage) -> ImageState? {
		states[image]
	}
	
	func image(for image: AssetImage?) -> Image? {
		guard let image else { return nil }
		switch state(for: image) {
		case .available(let image):
			return image
		case nil, .errored:
			Task { await download(image) }
			fallthrough
		case .downloading:
			return nil
		}
	}
	
	func download(_ image: AssetImage) async {
		guard inProgress.insert(image).inserted else { return }
		defer { inProgress.remove(image) }
		
		switch states[image] {
		case nil, .errored:
			break
		case .downloading, .available:
			return
		}
		
		if image.hasMetadata {
			do {
				let meta = try image.loadMetadata()
				// already checked against this version
				if meta.lastVersionCheckedAgainst == Self.version {
					states[image] = .available(try view(for: image))
					return
				}
			} catch {
				print("could not load metadata for \(image): \(error)")
			}
		}
		
		do {
			try await client.download(image)
			// caching this helps a lot with performance
			states[image] = .available(try view(for: image))
		} catch {
			print("error loading image from \(image.url) stored at \(image.localURL):")
			dump(error)
			states[image] = .errored(error)
			return
		}
		
		var meta = (try? image.loadMetadata()) ?? .init(
			versionDownloaded: Self.version,
			lastVersionCheckedAgainst: Self.version
		)
		meta.lastVersionCheckedAgainst = Self.version
		do {
			try image.save(meta)
		} catch {
			print("could not save metadata for \(image): \(error)")
		}
	}
	
	private func view(for image: AssetImage) throws -> Image {
		try Image(at: image.localURL) ??? ImageLoadingError.loadFromFileFailed
	}
	
	func clear() {
		states = [:]
		try? AssetImage.removeCachedFiles()
		// if any loads are in progress, they might still set the state right after this, but we'll just accept that.
	}
	
	enum ImageState {
		case downloading
		case errored(Error)
		case available(Image)
	}
	
	enum ImageLoadingError: Error {
		case loadFromFileFailed
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
