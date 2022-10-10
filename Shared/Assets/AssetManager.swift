import SwiftUI
import ValorantAPI
import UserDefault
import HandyOperators

@MainActor
final class AssetManager: ObservableObject {
	@Published private(set) var assets: AssetCollection?
	@Published private(set) var error: Error?
	private var isDownloading = false
	
	convenience init() {
		self.init(assets: Self.stored)
	}
	
	private init(assets: AssetCollection?) {
		_assets = .init(wrappedValue: assets)
		
		Task { await loadAssets() }
	}
	
	func loadAssets() async {
		guard !isDownloading else { return }
		isDownloading = true
		defer { isDownloading = false }
		
		self.error = nil
		do {
			assets = try await Self.loadAssets()
		} catch {
			self.error = error
		}
	}
	
	func reset() async {
		error = nil
		assets = nil
	}
	
	#if DEBUG
	static let forPreviews = AssetManager(assets: stored)
	static let mockEmpty = AssetManager(assets: nil)
	#endif
	
	static func loadAssets() async throws -> AssetCollection {
		let version = try await client.getCurrentVersion()
		if let stored, stored.version == version {
			return stored
		} else {
			return try await client.collectAssets(for: version)
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
