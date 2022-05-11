import SwiftUI
import ValorantAPI
import UserDefault
import HandyOperators

@MainActor
final class AssetManager: ObservableObject {
	@Published private(set) var assets: AssetCollection?
	@Published private(set) var progress: AssetDownloadProgress?
	@Published private(set) var error: Error?
	
	convenience init() {
		self.init(assets: Self.stored)
	}
	
	private init(assets: AssetCollection?) {
		_assets = .init(wrappedValue: assets)
	}
	
	func loadAssets(forceUpdate: Bool = false, skipExistingImages: Bool = false) async {
		guard progress == nil else { return }
		self.error = nil
		
		do {
			assets = try await Self.loadAssets(
				forceUpdate: forceUpdate,
				skipExistingImages: skipExistingImages
			) { progress in
				DispatchQueue.main.async { // TODO: switch to AsyncStream once it's out
					print(progress)
					self.progress = progress
				}
			}
		} catch {
			self.error = error
		}
		
		self.progress = nil
	}
	
	#if DEBUG
	static let forPreviews = AssetManager(assets: stored)
	static let mockEmpty = AssetManager(assets: nil)
	
	static let mockDownloading = AssetManager(mockProgress: .init(completed: 42, total: 69))
	
	private init(mockProgress: AssetDownloadProgress?) {
		_progress = .init(wrappedValue: mockProgress)
	}
	#endif
	
	static func loadAssets(
		forceUpdate: Bool = false,
		skipExistingImages: Bool = false,
		onProgress: AssetProgressCallback? = nil
	) async throws -> AssetCollection {
		let version = try await client.getCurrentVersion()
		if !forceUpdate, let stored = stored, stored.version == version {
			return stored
		} else {
			return try await client
				.collectAssets(for: version, skipExistingImages: skipExistingImages, onProgress: onProgress)
			<- { Self.stored = $0 }
		}
	}
	
	@UserDefault("AssetManager.stored")
	fileprivate static var stored: AssetCollection?
	
	private static let client = AssetClient()
}

extension AssetCollection: DefaultsValueConvertible {}

extension EnvironmentValues {
	var assets: AssetCollection? {
		get { self[Key.self] }
		set { self[Key.self] = newValue }
	}
	
	private struct Key: EnvironmentKey {
		@MainActor
		static let defaultValue: AssetCollection? = isInSwiftUIPreview ? AssetManager.stored : nil
	}
}
