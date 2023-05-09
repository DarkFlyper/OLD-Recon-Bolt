import SwiftUI
import ValorantAPI
import UserDefault
import HandyOperators
import WidgetKit

@MainActor
final class AssetManager: ObservableObject {
	@Published private(set) var assets: AssetCollection?
	@Published private(set) var error: Error?
	private var isDownloading = false
	
	var languageOverride: String? {
		storage.languageOverride
	}
	
	@Published private var storage = Storage()
	
	init() {
		let storage = Storage()
		self.storage = storage
		self.assets = storage.assets
		
		Task { await tryLoadAssets() }
	}
	
	private init(assets: AssetCollection?) {
		self.assets = assets
		
		Task { await tryLoadAssets() }
	}
	
	func setLanguageOverride(to language: String?) async {
		storage.languageOverride = language
		await tryLoadAssets()
		WidgetCenter.shared.reloadAllTimelines()
	}
	
	func tryLoadAssets() async {
		guard !isDownloading else { return }
		isDownloading = true
		defer { isDownloading = false }
		
		self.error = nil
		do {
			assets = try await loadAssets()
		} catch {
			self.error = error
		}
	}
	
	func reset() async {
		error = nil
		assets = nil
		storage.assets = nil
	}
	
	#if DEBUG
	static let forPreviews = AssetManager()
	static let mockEmpty = AssetManager(assets: nil)
	#endif
	
	private func loadAssets() async throws -> AssetCollection {
		let language = languageOverride
		?? Bundle.preferredLocalizations(from: Locale.valorantLanguages).first
		?? "en-US"
		let client = AssetClient(language: language)
		
		let version = try await client.getCurrentVersion()
		if let stored = storage.assets, stored.version == version, stored.language == language {
			return stored
		} else {
			return try await client.collectAssets(for: version)
			<- { storage.assets = $0 }
		}
	}
	
	private struct Storage {
		@UserDefault("AssetManager.stored", defaults: .shared)
		var assets: AssetCollection?
		@UserDefault("AssetManager.languageOverride", defaults: .shared)
		var languageOverride: String?
	}
}

extension AssetCollection: DefaultsValueConvertible {}

extension EnvironmentValues {
	var assets: AssetCollection? {
		get { self[Key.self] }
		set { self[Key.self] = newValue }
	}
	
	private enum Key: EnvironmentKey {
		#if WIDGETS
		@MainActor static let defaultValue: AssetCollection? = Managers.assets.assets
		#elseif DEBUG
		@MainActor static let defaultValue = isInSwiftUIPreview ? AssetManager.forPreviews.assets : nil
		#else
		@MainActor static let defaultValue: AssetCollection? = nil
		#endif
	}
}
